function idx=nearShell(shell_pts,shell_conns,pts)

[Centroid,SurfaceArea,Volume,CoM_ev123,CoM_eigenvectors,I1,I2,I_CoM,I_origin,patches] = mass_properties(shell_pts,shell_conns);

tfm=[CoM_eigenvectors;Centroid];

shell_pts_tfm=transformShell(shell_pts,tfm,-1,1);
pts_tfm=transformShell(pts,tfm,-1,1);

BB(1,:)=min(shell_pts_tfm);
BB(2,:)=max(shell_pts_tfm);

idx = (pts_tfm(:,1)>=BB(1,1)) & (pts_tfm(:,1)<=BB(2,1)) & ...
      (pts_tfm(:,2)>=BB(1,2)) & (pts_tfm(:,2)<=BB(2,2)) & ...
      (pts_tfm(:,3)>=BB(1,3)) & (pts_tfm(:,3)<=BB(2,3));