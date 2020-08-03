      program resample     !  resample 1sec SDTS to 3sec
      common /Cmvals/ mvals(1201,1201)
	 integer*2 mvals
      integer*2 kvals(21,21)
      character filename*12
      open(21,file='1sec.dat',status='old')
      rewind(21)
      num=0
10    read(21,'(a)',end=100) filename
      read(filename,'(1x,i2,1x,i3)') lat,lon
      num=num+1
      write(*,11) num,filename
11    format(i5,1h=,a)
      call fill_block(filename,lat,lon)
      call resamp
      open(23,file=filename(1:8)//'3sec',
     +     access='direct',recl=21*21*2)
      irec=0
      do 50 lat=1,60
      idy=(lat-1)*20
      do 50 lon=1,60
      idx=(lon-1)*20
      do 20 iy=1,21
      do 20 ix=1,21
      kvals(ix,iy)=mvals(idx+ix,idy+iy)
20    continue
      irec=irec+1
      write(23,rec=irec) kvals
50    continue
      close(23)
      go to 10
100   close(21)
      end
c-----------------------------------------------------------
      subroutine resamp
      common /Clvals/ lvals(3603,3603)
	 integer*2 lvals
      common /Cmvals/ mvals(1201,1201)
	 integer*2 mvals
      integer*2 max
      do 100 iy=1,1201
      iy2=iy*3
      iy1=iy2-2
      do 100 ix=1,1201
      ix2=ix*3
      ix1=ix2-2
      max=-500
      do 10 iiy=iy1,iy2
      do 10 iix=ix1,ix2
      if(lvals(iix,iiy).gt.max) max=lvals(iix,iiy)
10    continue
      mvals(ix,iy)=max
100   continue
      return
      end
c-----------------------------------------------------------
      subroutine fill_block(filename,lat,lon)
      common /Clvals/ lvals(3603,3603)
	 integer*2 lvals
      integer*2 kvals(61,61)
      character filename*12
      real*8 xxlat,xxlon,dcell,xlat,xlon
      xlat=lat
      xlon=-lon-1
      dcell=1.d0/3600.d0             !  size of 1 cell
      open(22,file='/topo1/1sec/'//filename,status='old',
     +     access='direct',recl=61*61*2,action='READ')
      irec=0
      do 50 lat=1,60
      idy=(lat-1)*60
      do 50 lon=1,60
      idx=(lon-1)*60
      irec=irec+1
      read(22,rec=irec) kvals
      do 10 iy=1,61
      do 10 ix=1,61
      lvals(idx+ix+1,idy+iy+1)=kvals(ix,iy)
10    continue
50    continue
      close(22)
c          now fill cells 1 row outside
      iy=1
      xxlat=xlat-dcell        !  1 cell below
      do 60 ix=1,3603
      xxlon=xlon + dfloat(ix-2)*dcell
      call one_sec_elevation(xxlon,xxlat,elev,*55)
      ielev=elev + .5
      lvals(ix,iy)=ielev
      go to 60
55    lvals(ix,iy)=-500      !  no data
60    continue
      iy=3603
      xxlat=xlat+dcell+1.d0  !  1 cell above
      do 70 ix=1,3603
      xxlon=xlon + dfloat(ix-2)*dcell
      call one_sec_elevation(xxlon,xxlat,elev,*65)
      ielev=elev + .5
      lvals(ix,iy)=ielev
      go to 70
65    lvals(ix,iy)=-500      !  no data
70    continue
      ix=1
      xxlon=xlon-dcell        !  1 cell left
      do 80 iy=1,3603
      xxlat=xlat + dfloat(iy-2)*dcell
      call one_sec_elevation(xxlon,xxlat,elev,*75)
      ielev=elev + .5
      lvals(ix,iy)=ielev
      go to 80
75    lvals(ix,iy)=-500      !  no data
80    continue
      ix=3603
      xxlon=xlon+dcell+1.d0   !  1 cell right
      do 90 iy=1,3603
      xxlat=xlat + dfloat(iy-2)*dcell
      call one_sec_elevation(xxlon,xxlat,elev,*85)
      ielev=elev + .5
      lvals(ix,iy)=ielev
      go to 90
85    lvals(ix,iy)=-500      !  no data
90    continue
      xxlat=-100.
      call one_sec_elevation(xxlon,xxlat,elev,*100)
100   return
      end
c-----------------------------------------------------------
      subroutine one_sec_elevation(xxlon,xxlat,elev,*)
      parameter (INC=60)
      parameter (IBUF=2*(INC+1)*(INC+1))
      parameter (NBUFS=3600/INC)
      real*8 xxlon,xxlat
c************************************************************
c          extract the 1-arc sec elevation for (xxlon,xxlat)
c          This is valid only for the SDTS US data.
c          one_sec_elevation= elevation in meters of point
c                         = < -500 = file does not exist
c************************************************************
c          The elevation of the 4 points that contain the 
c          (xxlon,xxlat) are found and the elevation is interpolated.
c          The 4 points are:
c                   2   3
c                   1   4
c************************************************************
      common /C_SDTS_vals/ krec,kvals(INC+1,INC+1)
	 integer*2 kvals
      dimension z(4)
      real*8 dx,dy
      save file_opened,ionce
      character file_opened*12,file*12
      character path*12
      integer*2 ival
      data path/'/topo1/1sec/'/
      data file_opened/'nxxwxxx.1sec'/
      data lu_data/81/
c*************************************************************
      if(xxlat.lt.-99.) then                !  close the file
	 close(lu_data)
	 file_opened='nxxwxxx.1sec'
	 ionce=0
         return
      end if
ccc      write(15,'(''one_sec='',2f15.8)') xxlon,xxlat
      call what_file(xxlon,xxlat,file,llx,lly,ix,iy,dx,dy)
ccc      write(15,'(''file='',a,4i5,2f15.8)') file,llx,lly,ix,iy,dx,dy
      if(file.ne.file_opened) then          !  open a different file
	 if(ionce.ne.0) close(lu_data)
	 ionce=0
	 krec=0
	 file_opened='nxxwxxx.1sec'
ccc	 write(15,'(''OPENing:'',a)') path//file
	 open(lu_data,file=path//file,status='old',
     +        access='direct',recl=IBUF,err=900,action='READ')
	 file_opened=file
	 ionce=1
      end if
      irec=(iy/INC)*NBUFS + (ix)/INC + 1
ccc      write(15,'(''ix,iy,irec='',2i6,i10)') ix,iy,irec
      if(irec.ne.krec) then
         read(lu_data,rec=irec) kvals
	 krec=irec
      end if
      ixx=mod(ix,INC)+1
      iyy=mod(iy,INC)+1
      ival=kvals(ixx,iyy)
ccc      write(15,'(''irec1='',i15)') irec1
ccc      read(lu_data,rec=irec1) ival
      z(1)=ival                     !  lower left corner
      if(dx.eq.0.d0) go to 100      !  exact match in x
      if(dy.eq.0.d0) go to 200      !  exact match in y

90    call fillz(z,kvals(ixx,iyy),kvals(ixx,iyy+1),
     +                kvals(ixx+1,iyy+1),kvals(ixx+1,iyy))
 
      z12=z(1) + (z(2)-z(1))*dy
      z43=z(4) + (z(3)-z(4))*dy
      elev=z12 + (z43-z12)*dx
ccc      if(abs(elev).gt.9000.) then
ccc	 write(*,99) elev,z,ixx,iyy,xxlon,xxlat,dx,dy,file_opened
ccc99       format('elev=',f7.1,4f7.1,2i5,4f15.7,1x,a)
ccc      end if
      return
c*************************************************************
100   if(dy.eq.0.d0) then          !  exact match
	 elev=z(1)
      else
         z(2)=kvals(ixx,iyy+1)         !  upper left corner
	 elev=z(1) + (z(2)-z(1))*dy    !  interpolate in y only
      end if
      go to 210
c*************************************************************
200   z(4)=kvals(ixx+1,iyy)         !  lower right corner
      elev=z(1) + (z(4)-z(1))*dx    !  interpolate in x only
210   if(abs(elev).gt.9000.) then
	 dx=.5
	 dy=.5
	 go to 90
      end if
      return
c*************************************************************
900   continue
ccc	 write(15,'(''OPEN failed'')')
      return 1
      end
c-----------------------------------------------------------------
      subroutine fillz(z,k1,k2,k3,k4)
      integer*2 k1,k2,k3,k4
      dimension z(4)
      ksum=0
      n=0
      if(k1.gt.-9999) then
	 ksum=k1
	 n=1
      end if
      if(k2.gt.-9999) then
	 ksum=ksum+k2
	 n=n+1
      end if
      if(k3.gt.-9999) then
	 ksum=ksum+k3
	 n=n+1
      end if
      if(k4.gt.-9999) then
	 ksum=ksum+k4
	 n=n+1
      end if
      if(n.ne.0) then
	 z_average=float(ksum)/float(n)
      else
	 z_average=0.
      end if

      if(k1.eq.-9999) then
	 z(1)=z_average
      else
         z(1)=k1                    !  lower left corner
      end if
      if(k2.eq.-9999) then
	 z(2)=k1
      else
         z(2)=k2                    !  upper left corner
      end if
      if(k3.eq.-9999) then
	 z(3)=z_average
      else
         z(3)=k3                    !  upper right corner
      end if
      if(k4.eq.-9999) then
	 z(4)=z_average
      else
         z(4)=k4                    !  lower right corner
      end if
      return
      end
c-----------------------------------------------------------------
      subroutine what_file(xxlon,xxlat,file,llx,lly,ix,iy,dx,dy)
c*****************************************************************************
c          create the file name "nxxwxxx.1sec" that contains (xxlon,xxlat)
c          the file name will be the LOWER RIGHT corner of the 1 deg x 1 deg
c          block that contains the point.
c          Thus, the point (40.5N, 105.5W) is in the file n40w105.1sec.
c*****************************************************************************
      real*8 xxlon,xxlat,xlr,xll,yll,delta,ytemp,xtemp,dx,dy
      character file*12
      data delta/3600.d0/     !  # data points per degree

      llx=-xxlon
      xlr=-llx
      if(xxlon.eq.xlr) then         !  right on the border
	 llx=llx-1
      end if
      xll=-llx-1
      lly=xxlat
      yll=lly
      write(file,'(1hn,i2.2,1hw,i3.3,5h.1sec)') lly,llx
      ytemp=xxlat-yll
      iy=ytemp*delta
      if(iy.lt.0 .or. iy.ge.3600) then
	 if(iy.lt.0) iy=0
	 if(iy.ge.3600) iy=3600
      end if
      dy=ytemp*delta-dfloat(iy)

      xtemp=xxlon-xll
      ix=xtemp*delta
      if(ix.lt.0 .or. ix.ge.3600) then
	 if(ix.lt.0) ix=0
	 if(ix.ge.3600) ix=3600
      end if
      dx=xtemp*delta-dfloat(ix)
      return
      end
c-----------------------------------------------------------------
