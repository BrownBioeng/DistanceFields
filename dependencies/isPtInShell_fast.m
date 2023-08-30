function [inside] = isPtInShell_fast(pts,connects,p,d,suppress)
% function [inside] = isPtInShell(pts,connects,p,d,suppress)
% This function tests if a pt is inside of a teselated shell. Can use an
% object that is from an IV or VRML file. However, note that the default
% connects from a vrml file are zero based index, and matlab uses 1 based
% index. So you need to correct this BEFORE running this code, with
% something like the following:
% d is an optional parameter, that is used as the constant 4th point for
% all tetrahedrons. It needs to have a little wiggle to make sure that its
% not planer to any of the other verticies. It is only a paremeter for
% speed optimization if one is running the code many times.
% suppress is either 1 or 0. If 1 suppress the display information, if 0
% show the display information.
%
% [pts connects] = read_vrml_fast('P:\ScaScrew\data\WRL.files\E16263_inner.wrl');
% connects(:,1:3) = connects(:,1:3) + 1;
%
% Code is based on an algorithm found from the following website:
% http://www.gvu.gatech.edu/~jarek/courses/4451/
% Using algorithms in the following lectures:
% http://www.gvu.gatech.edu/~jarek/courses/4451/Vectors.ppt
% http://www.gvu.gatech.edu/~jarek/courses/4451/Meshes.ppt
%
% From the powerpoint: 
% ================================================================
% A point p lies inside a solid S bounded by triangles Ti when p lies
% inside an odd number of tetrahedra, each defined by an arbitrary point o 
% and the 3 vertices of a different triangle Ti.
%
% Rationale
% Consider an oriented ray R from o through p. 
% Assume for simplicity that it does not hit any vertex or edge of the mesh.
% A point at infinity along the ray is OUT because we assume that the solid is finite.
% Assume that the portion of the ray after p intersects the triangle mesh k times. 
% If we walk from infinity towards p, each time we cross a triangle, we toggle classification.
% So, p is IN if and only if k is odd. 
% Let T denote the set of triangles hit be the portion of the ray that is beyond p.
% Let H denote the set of tetrahedra that contain p and have as vertices the point o and the 3 vertices of a triangle in the mesh.
% To each triangle of T corresponds a unique tetrahedron of H.
% So, the cardinality of T equals the cardinality of H.
% Hence we can use the parity of the cardinality of H.
%
% One test for point-in-tetrahedron test may be implemented as:
% PinT(a,b,c,d,p) := same(s(a,b,c,d),s(p,b,c,d),s(a,p,c,d),s(a,b,p,d),s(a,b,c,p))
% where s(a,b,c,d) returns (ab?ac)•ad > 0
%  - The test does not assume proper orientation of the triangles!
%
% The test used:
% Suggested by Nguyen Truong
% Write ap =  sab+tac+uad
% Solve for s, t, u (linear system of 3 equations)
% Requires 17 multiplications, 3 divisions, and 11 additions
% Check that s, t, and u are positive and that s+u+t<1
%
%
%=================================================================
%
% Evan Leventhal - 2/8/2007
%
%=================================================================


% d can be any point, however the code has problems if it lies on a vertext
% of any of the verticies in the shell. By trial and error, I learned that
% hard coding a point did not work well, because if that hard-coded point
% was too far away, there was not enough precision in the following
% calculations. So the solution to both these problems is to find roughly
% the centroid of the object, then add just a little wiggle using rand.
% Note also, that I don't guarantee the code to work if your test point is 
% similarly on the same line as a vertex, or shares a point with the shell.
if (exist('d','var')~=1),
    d = mean(pts) + rand([1 3]);
end;
if (exist('suppress','var')~=1)
    suppress=0;
end
    
% d = [23.3 44.45 -12.0];

len = length(connects);
num_inside = zeros(size(p,1),1);
if suppress==0,
    disp(['Total number of pts on shell: ' num2str(len)]);
    fprintf('Working on pt: ')
end
for i=1:len,

    %choose the current 3 points to test
    a = pts(connects(i,1),:);  
    b = pts(connects(i,2),:);
    c = pts(connects(i,3),:);
    

    %solve system of linear equations
    M = [b-a;c-a;d-a]';

    V = [p(:,1)-a(1) p(:,2)-a(2) p(:,3)-a(3)];
    A = M^-1*V'; A=A';
    % we are inside if all answers >0 and the sum<1
    inside_tri = (A(:,1)>0 & A(:,2)>0 & A(:,3)>0 & sum(A,2)<1);
    
    num_inside = sum([num_inside , double(inside_tri)],2);
	
    if suppress==0
        if i>1
            for j=0:log10(i-1)
                fprintf('\b'); % delete previous counter display
            end
        end
        fprintf('%d', i);
    end

end;
% We are inside if the point ends up inside an odd number of tetrahedrons
inside = logical(mod(num_inside,2));
if suppress==0
    fprintf('\n');
end