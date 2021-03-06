
a=360*rand(1);b=360*rand(1);c=360*rand(1); %Euler angs of true orientation
 A=[cosd(a) -sind(a) 0;sind(a) cosd(a) 0;0 0 1]...
    *[cosd(b) 0 sind(b);0 1 0;-sind(b) 0 cosd(b)]*[1 0 0;0 cosd(c) -sind(c);...
     0 sind(c) cosd(c)];
 ea=.1*pi/180*rand(1);eb=.1*pi/180*rand(1);ec=.1*pi/180*rand(1);
 E=[cos(ea) -sin(ea) 0;sin(ea) cos(ea) 0;0 0 1]...
    *[cos(eb) 0 sin(eb);0 1 0;-sin(eb) 0 cos(eb)]*[1 0 0;0 cos(ec) -sin(ec);...
     0 sin(ec) cos(ec)];
vo=rand(3,1);
vo=vo/sqrt(sum(vo.*vo))
vb=A*vo;
wo=rand(3,1);
wo=wo/sqrt(sum(wo.*wo))
wb=A*wo;
%%%%%%%%%%%%%%Calculation of Rotation matrix with no error in sensor values%%%%%%%%
K=zeros(4,4);
s=[1;1];%weights
B=s(1)*(vb*vo')+s(2)*(wb*wo');
S=B+B';
Z=[B(2,3)-B(3,2),B(3,1)-B(1,3),B(1,2)-B(2,1)]';
sig=trace(B);
K(1:3,1:3)=S-sig*eye(3);
K(4,1:3)=Z';
K(1:3,4)=Z;
K(4,4)=sig;
[E1, lambda]=eig(K)
[val1 posn1]=max(lambda);
[val2 posn2]=max(val1)
Ad=Quaternion_to_DCM(E1(:,posn2))
A-Ad
%%%%%%%%%%%%%%Calculation of Rotation matrix with error in sensor values
% dvb=[0;0;0];
% dwb=[0;0;0];
% dvo=[0;0;0];
% dwo=[0;0;0];
% vdb=vb+dvb;
% wdb=wb+dwb;
% vdo=vo+dvo;
% wdo=wo+dwo;


dvb=vb-E*vb;
dwb=wb-E*wb;
dvo=[0;0;0];
dwo=[0;0;0];
vdb=vb+dvb;
wdb=wb+dwb;
vdo=vo+dvo;
wdo=wo+dwo;


Ke=zeros(4,4);
se=[1;1];%weights
Be=se(1)*(vdb*vdo')+s(2)*(wdb*wdo');
Se=Be+Be';
Ze=[Be(2,3)-Be(3,2),Be(3,1)-Be(1,3),Be(1,2)-Be(2,1)]';
sige=trace(Be);
Ke(1:3,1:3)=Se-sige*eye(3);
Ke(4,1:3)=Ze';
Ke(1:3,4)=Ze;
Ke(4,4)=sige;
[E2, lambda]=eig(Ke)
[val1 posn1]=max(lambda);
[val2 posn2]=max(val1)
Ad=Quaternion_to_DCM(E2(:,posn2))
Error_Rot=Ad*A';

