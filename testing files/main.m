%simulation parameters
t_sim=6000; %seconds
time_step=100; %seconds

%satellite Parameters
LatExptOff=45;  %latitude outside which the HEPD experiment is off. 
                %We need a positive value here. Switch-off latitudes are assumed
                %to be symmetric about the equator.
Isat=7/12*[20*2+30^2 0 0;0 2*20^2 0; 0 0 20*2+30^2]*10^-4;

%orbit parameters
altitude=800000;
Omega=257.65*pi/180; %RAAN
omega=0; %argument of perigee. Has no significance for a circular orbit. 
%If an elliptical orbit is required, modifications must be made to the
%function ECIOrbitModel.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all
%num=t_sim/time_step;
num=30;
peak_torque=zeros(1,10);
oo=1;
for oo=1:1 %varying inclination
    inclination=(100-10*oo)*pi/180;
    dip=zeros(1,num);
    TA=zeros(3,3,num);
    lat=zeros(1,num);
    long=zeros(1,num);
    r_ECEF=zeros(3,num);
    r_ECI=ECIOrbitModel();
    for t=1:num
%       r_ECI=ECIOrbitModel(time_step*t,Omega,inclination,omega,altitude);
        r_ECEF(:,t)=DCMECItoECEF(time_step*t)*r_ECI(:,t);
        [lat(t) long(t)]=LatLong(r_ECEF(:,t));

        %initializing IGRF
        global gh
        if exist('GHcoefficients','file')==2
            load('GHcoefficients')
        else
            gh=GetIGRF11_Coefficients(1);
        end
        
        %Finding B, dip, and target attitude (here, target attitude assumes
        %the Cones-Not-Intersecting case.)
        B_ECEF_sph=igrf11syn(2011,800,lat(t),long(t));
        dip(t)=atand(-B_ECEF_sph(3)/sqrt(B_ECEF_sph(2)^2+B_ECEF_sph(1)^2));
        TA(:,:,t)=TargetAttitude([B_ECEF_sph(1);B_ECEF_sph(2);-B_ECEF_sph(3)]);
    end

    %Adding interpolation in relevant regions:
    ii=0; jj=0;
    for t=1:(num)
        if(((lat(t)>=LatExptOff)||(lat(t)<=-LatExptOff))&&((lat(t-1)<LatExptOff)&&(lat(t-1)>-LatExptOff)))
            tInterpStart(ii)=t;
            ii=ii+1;
        end

        if(((lat(t)>=LatExptOff)||(lat(t)<=-LatExptOff))&&((lat(t+1)<LatExptOff)&&(lat(t+1)>-LatExptOff)))
            tInterpStop(jj)=t;
            jj=jj+1;
        end
    end
    p=0;q=0;
    while ((p<ii)&&(q<jj))
        if(tInterpStart(p)<tInterpStop(q))
            t1=tInterpStart(p); t2=ttInterpStop(q0);
            temp=TA(:,:,t1)'*(TA(:,:,t1)-TA(:,:,t1-1))/time_step; %(R'*Rdot)
            omega_init=[temp(2,3); temp(3,1);temp(1,2)];
            temp=TA(:,:,t2)'*(TA(:,:,t2)-TA(:,:,t2-1))/time_step; %(R'*Rdot)
            omega_fin=[temp(2,3); temp(3,1);temp(1,2)];
            Rot=TA(:,:,t2)*TA(:,:,t1)';
            [val vec]=eigs(Rot);
            angle=acos((trace(Rot)-1)/2);
            for kk=1:3
                if(isreal(vec(:,kk)))
                    axis=vec(:,kk);
                end
            end
            A=[t1^3 t1^2 t1 1; t2^3 t2^2 t2 1; 3*t1^2 2*t1 1 0; 3*t1^2 2*t1 1 0];
            b=[0;angle;omega_init;omega_fin];
            cubic_coeffs=A\b;
            for t=t1:t2
                theta=polyval(cubic_coeffs,t);
                S=-skew_sym(axis);
                TA(:,:,t)=(eye(3)+sin(theta)*S+(1-cos(theta))*S^2)*TA(:,:,t1);
            end
            p=p+1;q=q+1;
        else
            q=q+1;
        end
    end

    %Converting to ECI reference frame. 
    TA_inertial=zeros(3,3,num);
    for t=1:num
        temp1=DCMSphToCart(r_ECEF(:,t));
        temp2=DCMECIToECEF(time_step*t);
        TA_inertial(:,:,t)=temp2*temp1'*TA(:,:,t)*temp1*temp2';
    end

    %Finding omega wrt body-fixed coordinates
    omega=zeros(3,num-1);
    h=zeros(3,num-1);
    for t=1:num-1
        TAdot=TA_inertial(:,:,t+1)-TA_inertial(:,:,t); 
        temp=TA_inertial(:,:,t)*TAdot'; %(R'*Rdot)
        omega(:,t)=[temp(2,3); temp(3,1);temp(1,2)];
        h(:,t)=Isat*omega(:,t);
    end

    %Finding Torque required
    torque=zeros(3,num-2);
    for t=1:num-2
        hdot=(h(:,t+1)-h(:,t))/time_step;
        torque(:,t)=hdot+skew_sym(omega(:,t))*h(:,t);
    end
    
    
    %Finding torque magnitude (Heat dissipation is proportional
    %to square of this.)
    torque_mag=zeros(1,num-2);
    for ii=1:num-2
        v=torque(:,ii);
        torque_mag(ii)=sqrt(sum(v.*v));
    end
    peak_torque(oo)=max(torque_mag);
    
    %Finding mechanical power
    KE_pow=zeros(1,num-2);
     for ii=1:num-2
        v=torque(:,ii);
        w=omega(:,ii);
        KE_pow(ii)=sum(v.*w);
     end
    
    %Plotting
    figure
    hc=plot(1:(num-2),torque_mag,1:(num-2),dip(1:(num-2))*.5*peak_torque(oo)/max(dip),'.');
    set(hc,'linewidth', 2);
    title(strcat('Torque magnitude and Dip versus time for orbit of inclination  ',int2str(100-10*oo),'_deg'))
    xlabel(strcat('Time, ',int2str(time_step), '*s'));
    legend('Torque magnitude, Nm',strcat('Dip, ',int2str(.5*peak_torque(oo)/max(dip)),' *deg'))
    grid on
%     figure
%     hc2=plot(KE_pow);
%     set(hc2,'linewidth', 2);
%     title(strcat('Mechanical power versus time for orbit of inclination  ',int2str(100-10*oo),' deg'))
%     xlabel(strcat('Time, ',int2str(time_step), '*s'));
%     ylabel('Mechanical Power, W');
%     grid on
end

%plotting peak torque vs inclination
hc3=plot(90:-10:0,peak_torque(1:10),'r');
set(hc3,'linewidth',2)
xlabel('Orbit Inclination')
ylabel('Peak Torque, Nm')
title('Peak Torque vs. Orbit Inclination')
grid on
        

        