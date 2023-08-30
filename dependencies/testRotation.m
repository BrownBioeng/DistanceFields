function [verdict] = testRotation(R);
% [verdict] = testRotation(R);
% Use this to test a 3x3 matrix for rotational properties.
% NB - The code does not allow for scaling rotations
% Input: R - 3x3 matrix to test
% 
% Output: verdict - Boolean.  1 = is a rotation

verdict = 1;
detCond = (abs(det(R)) < .9999) | (abs(det(R)) > 1.0001);

% If matrix is singular this condition will not execute but it will also not
% be a rotation matrix.
warning off MATLAB:singularMatrix
test = inv(R);
if any(test == Inf),
    if nargout == 1,
        verdict = 0;
    else
        error('MATLAB:testRotation:SingularMatrix','Matix is singular to working precision.  Program halted.');
    end;
    warning on MATLAB:singularMatrix    
    return;
end;
warning on MATLAB:singularMatrix
invCond = any(any(abs(R'-test) > .0005,1) | any(abs(R'-test) > .0005,2)');
if detCond | invCond;
    if nargout == 1,
        verdict = 0;
    else,
        error('MATLAB:testRotation:badRotation','Invalid Rotation. Fails determinant and inverse test. \rCheck validity of rotation matrix and try again');
    end;
end;

if det(R) < 0,
    if nargout == 1,
        verdict = 0;
    else,
       error('MATLAB:testRotation:LeftHanded','Left Handed Rotation.  Determinant is negative.');
   end;
end;