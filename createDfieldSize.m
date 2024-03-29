function Dfield=createDfieldSize(pts,cns,scale,grid_size,name,outpath)
%function Dfield = createDfieldSize(pts,cns,scale,grid_size,name,outpath)
%
%   Generates a distance field for a mesh with customizable parameters and
%   option to save to file. 
%
%   Inputs:
%      -pts: nx3 coordinates of mesh vertices, where n is the number of
%      vertices.
%      -cns: mx3 list of connections for mesh faces, where m is the number
%      of faces.
%      -scale: is the size of the dfields bounding box it is used in this
%       manner: dfieldBB = SCALE*boneBB + boneBB. Default is 0.25.
%      -grid_size: the number of points used to define the distance
%      field. The distance field is comprised of a grid of (grid_size x 
%      grid_size x grid_size) points from which the distance to the mesh 
%       surface is computed. Default is 100.
%      -name: the name of the mesh, if saving the Dfield to a .mat file.
%      "_Dfield" will be appended to the filename such that a mesh named
%      "sca15" will output a file named "sca15_Dfield.mat"
%      -outpath: the directory to output the Dfield, if saving the Dfield
%      to a .mat file. 
%
%   Outputs:
%      -Dfield: a structure containing a look-up table of grid points with
%      signed distances to the surface of the mesh (positive for outside of
%      the mesh, zero for on the surface, and negative for inside of the
%      mesh). The function lookUpDfieldPtsSize can use this structure to
%      interpolate the distance to the mesh surface for any other point
%      within the bounding box. 
%
%   Usage:
%   
%       Dfield = createDfieldSize(pts,cns)
%          --> Scale will be set to default of 0.25, and grid_size will be
%          set to default of 100. The distance field will not be saved to
%          file location.
%
%       Dfield = createDfieldSize(pts,cns,scale,gridsize)
%          --> Scale and grid_size will be set to defined values. The
%          distance field will not be saved to file location.
%
%       Dfield = createDfieldSize(pts,cns,scale,name,outpath)
%          --> Scale and grid_size will be set to defined values. The
%          distance field will be saved according to specified name and
%          output directory.
%
%   Marai GE, Crisco JJ, Laidlaw DH. 2006 A kinematics-based method for 
%   generating cartilage maps and deformations in the multi-articulating 
%   wrist joint from CT images. Conf Proc IEEE Eng Med Biol Soc 1, 2079–2082.
%   (doi:10.1109/IEMBS.2006.259742)
%       

%%

%Check for optional scale and grid_size
if exist('scale','var') == 0
    scale = 0.25;
end

if exist('grid_size','var') == 0
    grid_size = 100;
end

display('Building distance field...');
t1=tic;
% load points and connections
t2=tic;
%[pts cns]=read_vrml_fast(in);
time_load=toc(t2);
display(['Bone loaded in ' num2str(time_load) ' seconds']);

% calculate triangle centroids
t_centroids=(pts(cns(1:end,1),:)+pts(cns(1:end,2),:)+pts(cns(1:end,3),:))*(1/3);

% set size of distance map grid (X x Y x Z)
t3=tic;

% find the bounding box parameters for the bone
pts_min=min(pts);
pts_max=max(pts);
bbox=pts_max-pts_min;

% determine the start and stop point for the Dfield
start_pt=pts_min-bbox*scale;
end_pt=pts_max+bbox*scale;

% determine the length of each side of the Dfield
clength=end_pt-start_pt;
% determine the volume of each distance map voxel
voxel_size=clength/(grid_size-1);

% create a small matrix containing a diagonal of the points in the Dfield
for i=1:3
    pts_bbox(:,i)=linspace(start_pt(i),end_pt(i),grid_size)';
end

% create all the pts in the Dfield
[x y z]=meshgrid(pts_bbox(:,1),pts_bbox(:,2),pts_bbox(:,3));
pts_cube=[reshape(x,grid_size^3,1), reshape(y,grid_size^3,1), reshape(z,grid_size^3,1)];
time_cube=toc(t3);
display(['Cube generated in ' num2str(time_cube) ' seconds']);

% determine the distance to the bone surface (vertices and centroids included) for each point in the Dfield
t4=tic;
[idd d]=knnsearch([pts;t_centroids],pts_cube);
time_knn=toc(t4);
display(['Unsigned distances determined in ' num2str(time_knn) ' seconds']);

% determine which points are within the bone
t5=tic;
display('Determining signed distances...');
idn1=nearShell(pts,cns,pts_cube); % determine cube pts close to the bone
d_subset=d(idn1); % create a subset of the distances

% this portion of code is used to speed up the code for determining which points are within the bone
% the code uses vector summation to do calculations.
% summing two vectors of >300,000 points takes more time than summing 2 vectors of 10,000 points
% the time does not scale linearly with the number of points
% to speed things up, the points are checked in chunks
% the size of the chunks is dictated by the variable 'ss'
k=0;
ss=100;
idn1_subset=zeros([size(idn1,1) 2]);
idn2=[];
disp(['Total number of iterations: ' num2str(ss)]);
fprintf('Working on iteration: ')
for i=1:size(idn1,1)/ss:1+size(idn1,1)-(size(idn1,1)/ss)

    if i>1
        fprintf('\b\b\b'); % delete previous counter display
    end
    fprintf('%03d', k+1);

    idn1_subset(:,1)=zeros(size(idn1));
    idn1_subset(i:size(idn1,1)/ss+(k*size(idn1,1)/ss),1) = ...
        idn1(i:size(idn1,1)/ss+(k*size(idn1,1)/ss));

    idn1_subset(i:size(idn1,1)/ss+(k*size(idn1,1)/ss),2) = ...
        idn1(i:size(idn1,1)/ss+(k*size(idn1,1)/ss));
    idn1_subset=logical(idn1_subset);

    pts_cube_subset=pts_cube(idn1_subset(:,1),:);
    idn2=[idn2; isPtInShell_fast(pts,cns,pts_cube_subset,mean(pts)+rand(1,3),1)]; % determine the cube points that are within the bone
    k=k+1;

end
fprintf('\n');
idn2=logical(idn2);

d_subset_signed=d_subset;d_subset_signed(idn2)=d_subset(idn2)*-1; % change the sign of the distances
d_final=d;d_final(idn1)=d_subset_signed; % recreate the full set of distances (now signed)
idn3=d_final<0; % determine the indeces where the cube point is whithin the bone (out of all points)
time_sign=toc(t5);
time_d=toc(t4);
display(['Distance sign determined in ' num2str(time_sign) ' seconds']);
display(['Total time to determine signed distances: ' num2str(time_d) ' seconds']);

time_total=toc(t1);
display(['Distance field generated in ' num2str(time_total) ' seconds']);

Dfield.im=reshape(d_final,grid_size,grid_size,grid_size);
Dfield.voxelsize=voxel_size;
Dfield.offset=start_pt;
%Dfield.path=pathstr;
Dfield.cs=0;

if exist('outpath','var')
    save(fullfile(outpath,[name '_Dfield.mat']),'Dfield','-mat');
    disp(['Saved: ' fullfile(outpath,[name '_Dfield.mat'])]);
end

%% read a Dfield from CS
% 
% %display('Loading CS distance field...');
% t6=tic;
% Dfield.im = read_mri(in);
% fid = fopen(fullfile(in, 'vsize'),'r');
% Dfield.voxelsize = fscanf(fid,'%f')';
% fclose(fid);
% fid = fopen(fullfile(in, 'cooroffset.dat'),'r');
% Dfield.offset = fscanf(fid,'%f')';
% fclose(fid);
% Dfield.cs=1;
% Dfield.path=in;
% Dfield.file=[];
% time_cs=toc(t6);
% display(['CS distance field loaded in ' num2str(time_cs) ' seconds']);
end