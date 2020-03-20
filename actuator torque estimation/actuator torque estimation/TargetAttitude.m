function DCM=TargetAttitude(eB) 
%alpha=0 
%output is DCM from local ECEF to Body-Fixed
en=[0;0;1]; %nadir vector
x_new=eB/sqrt(sum(eB.*eB));
y_new=cross(en,x_new);
z_new=cross(x_new,y_new);
y_new=y_new/sqrt(sum(y_new.*y_new));
z_new=z_new/sqrt(sum(z_new.*z_new));
DCM=[x_new y_new z_new]';
end