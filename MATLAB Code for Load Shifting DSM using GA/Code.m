price=[12 9.19 12.27 20.69 26.82 27.35 13.81 17.31 16.42 9.83 8.63 8.87 8.35 16.44 16.19 8.87 8.65 8.11 8.25 8.10 8.14 8.13 8.34 9.35];
t=[0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23];
solar=[45.5 49.2 50.23 52.34 55.9 57.4 52.1 50 48.1 37.9 29.1 15.0 6.13 0 0 0 0 0 0 0 0 17.42 30.42 40.98];
n=input('Enter the population number:');
filename = 'inputfile.xlsx';
sheet = 1;
Total_devices = xlsread(filename,sheet,'B1');
[num,txt,raw]= xlsread(filename,sheet,'A3:A8');
Device_type=txt;
Total_Device_types=6;
Device_count= xlsread(filename,sheet,'B3:B8');
Starting_time= xlsread(filename,sheet,'C3:C8');
Connection_time= xlsread(filename,sheet,'K3:K8');
Connection_power= xlsread(filename,sheet,'E3:J8');
sheet=2;
pload= xlsread(filename,sheet,'A2:A25');
maxi_price=max(price);
sum=0;lsum=0;
for i=1:24
    sum=sum+price(i);
    lsum=lsum+pload(i);
end
avg=sum/24;
for i=1:24
    obj(i)=(avg/maxi_price)*(1/price(i))*lsum;
end
for i=1:n
    for j=1:24
        energy(i,j)=pload(j)-solar(j);
    end
end
%Device parameters
for m=1:n
    k=1;
    for i=1:Total_Device_types
        for j=1:Device_count(i)
            Device(m,k).Device_name=Device_type(i);
            Device(m,k).Device_number=j;
            Device(m,k).Start_time=Starting_time(i);
            Device(m,k).Operation_time=Starting_time(i);
            Device(m,k).Connection_period=Connection_time(i);
            for q=1:Connection_time(i)
                Device(m,k).Connection_energy(q)=Connection_power(i,q);
            end
            if(24-Starting_time(i)-Connection_time(i))>12
                Device(m,k).max_delay=12;
            else
                Device(m,k).max_delay=24-Starting_time(i)-Connection_time(i);
            end
            Device(m,k).max_Start_time=Device(m,k).Start_time+Device(m,k).max_delay;
            Device(m,k).apparent_min_delay=Device(m,k).Start_time-Device(m,k).Operation_time;
            Device(m,k).apparent_max_delay=Device(m,k).Start_time+Device(m,k).max_delay-Device(m,k).Operation_time;
            k=k+1;
        end
    end
end
%Initialization
for i=1:n
    for j=1:Total_devices
        Device(i,j).Delay=floor(Device(i,j).apparent_min_delay+(Device(i,j).apparent_max_delay-Device(i,j).apparent_min_delay)*rand());
    end
end

%Fittness
for iter=1:800
    for i=1:n
        for k=1:Total_devices
            for j=1:24
                if(j==Device(i,k).Operation_time)
                    for l=1:Device(i,k).Connection_period
                        energy(i,j+l-1)=energy(i,j+l-1)-Device(i,k).Connection_energy(l);
                        energy(i,Device(i,k).Start_time+Device(i,k).Delay+l-1)=energy(i,Device(i,k).Start_time+Device(i,k).Delay+l-1)+Device(i,k).Connection_energy(l);
                    end
                end
            end
        end
    end

    for i=1:n
        for j=1:Total_devices
            Device(i,j).Operation_time=Device(i,j).Start_time+Device(i,j).Delay;
        end
    end

    
    total=0;
    for i=1:n
        error(i)=0;
        for j=1:24
            error(i)=error(i)+power((obj(j)-energy(i,j)),2);
            fitness(i)=(1/(1+error(i)));
        end
        total=fitness(i)+total;
    end
    avg_fitness(iter)=total/n;
    for i=1:n
        for j=i+1:n
            if(fitness(i)>fitness(j))
                temp=fitness(i);
                fitness(i)=fitness(j);
                fitness(j)=temp;
                for m=1:Total_devices
                    tmp=Device(i,m);
                    Device(i,m)=Device(j,m);
                    Device(j,m)=tmp;
                end
                for m=1:24
                    temp=energy(i,m);
                    energy(i,m)=energy(j,m);
                    energy(j,m)=temp;
                end
            end
        end
    end

    for i=1:n
        prob(i)=fitness(i)/total;
    end
    for i=1:n
        c(i)=0;
        for j=1:i
            c(i)=c(i)+prob(j);
        end
    end


    for i=1:n
        ra(i)=rand();
    end
    for i=1:n
        for j=1:n
            if(ra(i)<c(j))
                for m=1:Total_devices
                    newchrome(i,m)=Device(j,m);
                end
                for m=1:24
                    newchrome_energy(i,m)=energy(j,m);
                end
                break;
                new_fitness(i)=fitness(j);
            end
        end
    end

    pc=0.9;q=1;
    for i=1:n
        ra(i)=rand();
        if(ra(i)<pc)
            parentindex(q)=i;
            for m=1:Total_devices
                parent(q,m)=newchrome(i,m);
            end
            for m=1:24
                parent_energy(q,m)=newchrome_energy(i,m);
            end
            q=q+1;
        end
    end

    q=q-1;
    z=1;
    vmin=0.75;vmax=1.5;

    for i=1:(q-1)
        for j=1:Total_devices
            
            u=rand();
            child(z,j)=parent(i,j);
            for m=1:24
                child_energy(z,m)=parent_energy(i,m);
            end
            child(z,j).Delay=floor((u*parent(i,j).Delay)+((1-u)*parent(i+1,j).Delay));
            if (child(z,j).Delay>child(z,j).apparent_max_delay)
                child(z,j).Delay=child(z,j).apparent_max_delay;
            end
            if (child(z,j).Delay<child(z,j).apparent_min_delay)
                child(z,j).Delay=child(z,j).apparent_min_delay;
            end
            k1(z,j)=child(z,j).Delay;
            
            u=rand();
            child(z+1,j)=parent(i+1,j);
            for m=1:24
                child_energy(z+1,m)=parent_energy(i+1,m);
            end
            child(z+1,j).Delay=floor(((1-u)*parent(i,j).Delay)+((u)*parent(i+1,j).Delay));
            if (child(z+1,j).Delay>child(z+1,j).apparent_max_delay)
                child(z+1,j).Delay=child(z+1,j).apparent_max_delay;
            end
            if (child(z+1,j).Delay<child(z+1,j).apparent_min_delay)
                child(z+1,j).Delay=child(z+1,j).apparent_min_delay;
            end
            k1(z+1,j)=child(z+1,j).Delay;
            
            u=rand();
            child(z+2,j)=parent(i,j);
            for m=1:24
                child_energy(z+2,m)=parent_energy(i,m);
            end
            child(z+2,j).Delay=floor(0.5*(parent(i,j).Delay+parent(i+1,j).Delay));
            if (child(z+2,j).Delay>child(z+2,j).apparent_max_delay)
                child(z+2,j).Delay=child(z+2,j).apparent_max_delay;
            end
            if (child(z+2,j).Delay<child(z+2,j).apparent_min_delay)
                child(z+2,j).Delay=child(z+2,j).apparent_min_delay;
            end
            k1(z+2,j)=child(z+2,j).Delay;
            
            u=rand();
            child(z+3,j)=parent(i+1,j);
            for m=1:24
                child_energy(z+3,m)=parent_energy(i+1,m);
            end
            child(z+3,j).Delay=floor(0.5*((u*(parent(i,j).Delay+parent(i+1,j).Delay))+((1-u)*(child(z+3,j).apparent_max_delay+child(z+3,j).apparent_min_delay))));
            if (child(z+3,j).Delay>child(z+3,j).apparent_max_delay)
                child(z+3,j).Delay=child(z+3,j).apparent_max_delay;
            end
            if (child(z+3,j).Delay<child(z+3,j).apparent_min_delay)
                child(z+3,j).Delay=child(z+3,j).apparent_min_delay;
            end
            k1(z+3,j)=child(z+3,j).Delay;
            end
        z=z+4;
    end

    u=rand();
    for j=1:Total_devices
            u=rand();
            child(4*q-3,j)=parent(i,j);
            for m=1:24
                child_energy(4*q-3,m)=parent_energy(i,m);
            end
            child(4*q-3,j).Delay=floor((u*parent(i,j).Delay)+((1-u)*parent(i+1,j).Delay));
            if (child(4*q-3,j).Delay>child(4*q-3,j).apparent_max_delay)
                child(4*q-3,j).Delay=child(4*q-3,j).apparent_max_delay;
            end
            if (child(4*q-3,j).Delay<child(4*q-3,j).apparent_min_delay)
                child(4*q-3,j).Delay=child(4*q-3,j).apparent_min_delay;
            end
            k1(4*q-3,j)=child(4*q-3,j).Delay;
            
            u=rand();
            child(4*q-2,j)=parent(i+1,j);
            for m=1:24
                child_energy(4*q-2,m)=parent_energy(i+1,m);
            end
            child(4*q-2,j).Delay=floor(v*((1-u)*parent(i,j).Delay)+((u)*parent(i+1,j).Delay));
            if (child(4*q-2,j).Delay>child(4*q-2,j).apparent_max_delay)
                child(4*q-2,j).Delay=child(4*q-2,j).apparent_max_delay;
            end
            if (child(4*q-2,j).Delay<child(4*q-2,j).apparent_min_delay)
                child(4*q-2,j).Delay=child(4*q-2,j).apparent_min_delay;
            end
            k1(4*q-2,j)=child(4*q-2,j).Delay;
            
            u=rand();
            child(4*q-1,j)=parent(i,j);
            for m=1:24
                child_energy(4*q-1,m)=parent_energy(i,m);
            end
            child(4*q-1,j).Delay=floor(v*0.5*(parent(i,j).Delay+parent(i+1,j).Delay));
            if (child(4*q-1,j).Delay>child(4*q-1,j).apparent_max_delay)
                child(4*q-1,j).Delay=child(4*q-1,j).apparent_max_delay;
            end
            if (child(4*q-1,j).Delay<child(4*q-1,j).apparent_min_delay)
                child(4*q-1,j).Delay=child(4*q-1,j).apparent_min_delay;
            end
            k1(4*q-1,j)=child(4*q-1,j).Delay;
            
            u=rand();
            child(4*q,j)=parent(i+1,j);
            for m=1:24
                child_energy(4*q,m)=parent_energy(i+1,m);
            end
            child(4*q,j).Delay=floor(v*0.5*((u*(parent(i,j).Delay+parent(i+1,j).Delay))+((1-u)*(child(4*q,j).apparent_max_delay+child(4*q,j).apparent_min_delay))));
            if (child(4*q,j).Delay>child(4*q,j).apparent_max_delay)
                child(4*q,j).Delay=child(4*q,j).apparent_max_delay;
            end
            if (child(4*q,j).Delay<child(4*q,j).apparent_min_delay)
                child(4*q,j).Delay=child(4*q,j).apparent_min_delay;
            end
            k1(4*q,j)=child(4*q,j).Delay;
    end
    
    for i=4*q+1:5*q
        for j=1:Total_devices
            child(i,j)=parent(i-4*q,j);
        end
        for m=1:24
            child_energy(i,m)=parent_energy(i-4*q,m);
        end
    end
    

    for i=1:5*q
        for j=1:24
            for k=1:Total_devices
                if(j==child(i,k).Operation_time)
                    for l=1:child(i,k).Connection_period
                        child_energy(i,j+l-1)=child_energy(i,j+l-1)-child(i,k).Connection_energy(l);
                        child_energy(i,child(i,k).Start_time+child(i,k).Delay+l-1)=child_energy(i,child(i,k).Start_time+child(i,k).Delay+l-1)+child(i,k).Connection_energy(l);
                    end
                end
            end
        end
    end

    for i=1:5*q
        for j=1:Total_devices
            child(i,j).Operation_time=child(i,j).Start_time+child(i,j).Delay;
        end
    end

    for i=1:5*q
        child_error(i)=0;
        for j=1:24
            child_error(i)=child_error(i)+power((obj(j)-child_energy(i,j)),2);
            child_fitness(i)=(1/(1+child_error(i)));
        end
    end

    for i=1:5*q
        for j=i+1:5*q
            if(child_fitness(i)<child_fitness(j))
                temp=child_fitness(i);
                child_fitness(i)=child_fitness(j);
                child_fitness(j)=temp;
                for m=1:Total_devices
                    tmp=child(i,m);
                    child(i,m)=child(j,m);
                    child(j,m)=tmp;
                end
                for m=1:24
                    tmp1=child_energy(i,m);
                    child_energy(i,m)=child_energy(j,m);
                    child_energy(j,m)=tmp1;
                end
            end
        end
    end

    pm=0.1;
    noe=floor(n/2)*Total_devices;
    mut=pm*noe;
    totalmut=round(mut);
    pos=floor((1+(noe-1)*rand(totalmut,1)));
    row=fix(pos/Total_devices);
    col=(pos-(row*Total_devices))+1;
    for i=1:floor(n/2)
        for j=1:Total_devices
            for m=1:totalmut
                if((i==row(m)) && (j==col(m)))
                    child(i,j).Delay=floor(child(i,j).apparent_min_delay+(child(i,j).apparent_max_delay-child(i,j).apparent_min_delay)*rand());
                    if (child(i,j).Delay>child(i,j).apparent_max_delay)
                        child(i,j).Delay=child(i,j).apparent_max_delay;
                    end
                    if (child(i,j).Delay<child(i,j).apparent_min_delay)
                        child(i,j).Delay=child(i,j).apparent_min_delay;
                    end
                end
            end
        end
    end

    for i=1:floor(n/2)
        for j=1:Total_devices
            Device(i,j)=child(i,j);
        end
        for m=1:24
            energy(i,m)=child_energy(i,m);
        end
    end
    super_solution=max(fitness);
    best(iter)=max(fitness);
    line(iter)=iter;
    plot(iter,super_solution,'erasemode','none');
    drawnow
end
for i=1:24
    ener(i)=energy(1,i);
end
hold on;
stairs(t,obj,'m');
stairs(t,pload,'k');
stairs(t,ener,'g');
hold off;
