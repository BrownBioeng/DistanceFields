function [Rg,Tg] = doTransform(RT,statTform,direction,points);
%
%[Rg,Tg] = doTransform(RT,statTform,direction,points);
%  Perform a kinematic transform:  x1 = Rx + T both forward and reverse To
%  be used in conjunction with the transformShell program.
%
% Inputs:   RT - EITHER 4x3 matrix comprising a Rotation and Translation or a
%                list of points to be transformed
%           statTform - 4x3 matrix comprising the Rotation and Translation
%                       to apply to RT
%           direction -  1 applies a forward transform 
%                       -1 does backward transform
%           points - If you are transforming points specify 1 otherwise, 0
%
% Outputs:  Rg - Transformed Rotation matrix
%           Tg - Transformed Translation

statR = statTform(1:3,1:3);
statT = statTform(4,1:3);
    
if ~points,
    R = RT(1:3,:);
	T = RT(4,:);
    try
        testRotation(R);
    catch
        [msg,msgID] = lasterr;
        if ~isempty(strfind(msgID,'LeftHanded')),
            fprintf('%s\nReversing Matrix.',msg);
            R = -R;
        else,
            rethrow(lasterror);
        end;
    end;
    if direction == 1,
        Rg = statR*R;
		Tg = statR*T'+statT';
        Tg = Tg';
    else,
        Rg = statR'*R;
        Tg = statR'*(T'- statT');
        Tg = Tg';
    end;
else,
    ind = find(1==(size(RT)~=3));
    if isempty(ind), %3x3 matrix
        n_pts = 3;
    elseif max(size(ind) > 1),
        error('Those are not 3-dimensional points.');
    else,
    	n_pts = size(RT,ind);
        if ind == 2, % If 3xn, flip to nx3
            RT = RT';
        end;
    end;
   
	trans_mat = [statT(1)*ones(n_pts,1) ...
                 statT(2)*ones(n_pts,1) ...
				 statT(3)*ones(n_pts,1)];
				 
	if direction == 1, 
		R_d = statR*RT';
		R_d = R_d';
		Rg = R_d + trans_mat;
	end;
	
	if direction == -1, 
		RT = RT - trans_mat;
		Rg = statR'*RT';
		Rg = Rg';
	end;
    Tg = 'Your points have been assimiliated';
end;