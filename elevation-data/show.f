      program show         !  resample 1sec SDTS to 3sec
      integer*2 mvals(21,21)
      character filename*12
      write(*,'(''filename='',$)')
      read(*,'(a)') filename
      open(23,file=filename(1:8)//'3sec',
     +     access='direct',recl=21*21*2)
      open(31,file='show.out')
      rewind(31)
      irec=0
      do 50 lat=1,60
      do 50 lon=1,60
      irec=irec+1
      read(23,rec=irec) mvals
      write(31,11) lat,lon,irec
11    format('lat,lon,irec=',2i3,i10)
      do 20 iy=21,1,-1
20    write(31,21) (mvals(ix,iy),ix=1,21)
21    format(10x,21i5)
50    continue
      close(23)
      close(31)
      end
