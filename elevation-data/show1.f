      program show1        !  resample 1sec SDTS to 3sec
      integer*2 mvals(61,61)
      character filename*12
      write(*,'(''filename='',$)')
      read(*,'(a)') filename
      open(23,file='/topo1/1sec/'//filename(1:7)//'.1sec',
     +     access='direct',recl=61*61*2,status='old')
      open(31,file='show1.out')
      rewind(31)
      irec=0
      do 50 lat=1,2
      do 50 lon=1,60
      irec=irec+1
      read(23,rec=irec) mvals
      write(31,11) lat,lon,irec
11    format('lat,lon,irec=',2i3,i10)
      do 20 iy=61,1,-1
20    write(31,21) (mvals(ix,iy),ix=1,21)
21    format(10x,61i5)
50    continue
      close(23)
      close(31)
      end
