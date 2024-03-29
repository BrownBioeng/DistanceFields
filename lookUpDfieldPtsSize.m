function distance = lookUpDfieldPtsSize(Dfield,pts,Rpose,Tpose,grid_size)
% function distance = lookUpDfieldPtsSize(Dfield,pts,Rpose,Tpose,size)
%
%   Uses distance field to interpolate between grid points and compute the
%   distance from specified points to the surface of the mesh.
%
%   Inputs:
%      -Dfield: distance field structure generated with createDfieldSize.m
%      -pts: px3 coordinates of points from which to compute a signed distance to
%      the surface of the mesh.
%      -Rpose: 3x3 rotation matrix for rotating distance field to pose of
%      interest.
%      -Tpose: 1x3 or 3x1 vector for translating distance field to pose of interest. 
%      -grid_size: The number of points used to define the distance
%      field. This would have been specified when generating the distance
%      field in createDfieldSize. The default is 100.
%
%   Outputs:
%      -distance: 1xp array of signed distances from each point to the
%      surface of the mesh. Note that if points are outside of the bounding
%      box, they will be set to the max_distance (currently 20). 
%
%   Marai GE, Crisco JJ, Laidlaw DH. 2006 A kinematics-based method for 
%   generating cartilage maps and deformations in the multi-articulating 
%   wrist joint from CT images. Conf Proc IEEE Eng Med Biol Soc 1, 2079–2082.
%   (doi:10.1109/IEMBS.2006.259742)
%       
%
%neutral pose
if nargin < 3
    Rpose=[1 0 0;0 1 0; 0 0 1];
    Tpose=[0 0 0];
end

im = Dfield.im;
voxelsize = Dfield.voxelsize;
offset = Dfield.offset;

max_distance = 20;
% max_distance=max(max(max(im))); %max slows the function down
% considerably. Just set distance to a value and come back to approximation
% later.

% move pts back to neutral pose (maps points of interest into appropriate
% place on bone of interest)
pts = RT_transform(pts,Rpose,Tpose,0);

if Dfield.cs == 1
    lookup = [(pts(:,1) - offset(1) + voxelsize(1))./voxelsize(1)... %xvalue, dcube space
              (pts(:,3) - offset(3) + voxelsize(3))./voxelsize(3)... %yvalue, dcube space
              (pts(:,2) - offset(2) + voxelsize(2))./voxelsize(2)];  %zvalue, dcube space
else
    lookup = [(pts(:,1) - offset(1) + voxelsize(1))./voxelsize(1)... %xvalue, dcube space
              (pts(:,2) - offset(2) + voxelsize(2))./voxelsize(2)... %yvalue, dcube space
              (pts(:,3) - offset(3) + voxelsize(3))./voxelsize(3)];  %zvalue, dcube space
end

% begin tricubic interpolation    
dX = lookup(:,2); dY = lookup(:,1); dZ = lookup(:,3);
i1x = floor(dX); i2x = i1x + 1;
i1y = floor(dY); i2y = i1y+1;
i1z = floor(dZ); i2z = i1z+1;

Iinclude = find(i2x < grid_size+1 & i2y < grid_size+1 & i2z < grid_size+1 & i1x > 0 & i1y > 0 & i1z > 0);
Iexclude = find(i2x > grid_size | i2y > grid_size | i2z > grid_size | i1x < 1 | i1y < 1 | i1z < 1);

im_array = reshape(im,numel(im),1);
% convert X Y Z index to one-dimensional index dim[100 x 100 x 100] becomes
% [ones + 100's + 10000's]
% if max([i1x i1y i1z i2x i2y i2z]) < 101 && min([i1x i1y i1z i2x i2y i2z]) > 0
P0 = im_array(i1x(Iinclude) + i1y(Iinclude).*grid_size-grid_size  + i1z(Iinclude).*(grid_size^2)-(grid_size^2));
P1 = im_array(i2x(Iinclude) + i1y(Iinclude).*grid_size-grid_size  + i1z(Iinclude).*(grid_size^2)-(grid_size^2));
P2 = im_array(i2x(Iinclude) + i1y(Iinclude).*grid_size-grid_size  + i2z(Iinclude).*(grid_size^2)-(grid_size^2));
P3 = im_array(i1x(Iinclude) + i1y(Iinclude).*grid_size-grid_size  + i2z(Iinclude).*(grid_size^2)-(grid_size^2));
P4 = im_array(i1x(Iinclude) + i2y(Iinclude).*grid_size-grid_size  + i1z(Iinclude).*(grid_size^2)-(grid_size^2));
P5 = im_array(i2x(Iinclude) + i2y(Iinclude).*grid_size-grid_size  + i1z(Iinclude).*(grid_size^2)-(grid_size^2));
P6 = im_array(i2x(Iinclude) + i2y(Iinclude).*grid_size-grid_size  + i2z(Iinclude).*(grid_size^2)-(grid_size^2));
P7 = im_array(i1x(Iinclude) + i2y(Iinclude).*grid_size-grid_size  + i2z(Iinclude).*(grid_size^2)-(grid_size^2));

tmp1 = dX(Iinclude) - i1x(Iinclude);
tmp2 = i2x(Iinclude) - dX(Iinclude);

%ABCD defines the plane parallel to YOZ and passing through point.
A = (dX(Iinclude) - i1x(Iinclude)).*P2 + (-dX(Iinclude) + i2x(Iinclude)).*P3;
B = tmp1.*P1 + tmp2.*P0;
C = tmp1.*P5 + tmp2.*P4;
D = tmp1.*P6 + tmp2.*P7;

tmp1 = dY(Iinclude) - i1y(Iinclude);
tmp2 = i2y(Iinclude) - dY(Iinclude);
E = tmp1 .* D + tmp2 .* A;
F = tmp1 .* C + tmp2 .* B;
tmp1 = dZ(Iinclude) - i1z(Iinclude);
tmp2 = i2z(Iinclude) - dZ(Iinclude);
distance(Iinclude) = tmp1 .* E + tmp2 .* F;
distance(Iexclude) = max_distance; % set to max Dfield distance for variables that are out of bounds