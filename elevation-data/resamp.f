      program resam     !  resample 1sec SDTS to 3sec
      integer*2 kvals(61,61),mvals(21,21)
      character filename*12
      num=0
      filename='n40w080.1sec'
      num=num+1
      write(*,11) num,filename
11    format(i5,1h=,a)
      open(22,file='/topo1/1sec/'//filename,status='old',
     +     access='direct',recl=61*61*2,action='READ')
ccc      open(23,file=filename(1:8)//'3sec',
ccc     +     access='direct',recl=21*21*2)
      irec=0
      do 50 lat=1,60
      do 50 lon=1,60
      irec=irec+1
      read(22,rec=irec) kvals
      do 20 j=61,1,-1
20    write(*,21) j,(kvals(i,j),i=1,61)
21    format(i2,1h=,61i4)
      call resamp(kvals,mvals)
ccc      write(23,rec=irec) mvals
      do 30 j=21,1,-1
30    write(*,31) j,(mvals(i,j),i=1,21)
31    format(i2,1h=,21i4)
      if(irec.ne.0) stop
50    continue
      close(22)
ccc      close(23)
      end
      subroutine resamp(kvals,mvals)
      integer*2 kvals(61,61),mvals(21,21),max
      do 100 i=1,21
      i1=(i-1)*3
      do 100 j=1,21
      j1=(j-1)*3
      max=-500
      do 10 ii=1,3
      do 10 jj=1,3
      if(kvals(i1+ii,j1+jj).gt.max) max=kvals(i1+ii,j1+jj)
10    continue
      mvals(i,j)=max
100   continue
      return
      end
