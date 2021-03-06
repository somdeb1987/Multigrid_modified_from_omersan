!---------------------------------------------------------------------------!
!Multigrid scheme (5 level)
!Full-weighting is used as restriction operator
!Bilinear interpolation procedure is used as prolongation operator
!---------------------------------------------------------------------------!
subroutine multigrid(nx,ny,nz,dx,dy,dz,f,u,tol)

    implicit none

    integer::nx,ny,nz
    real(kind=8) ::dx,dy,dz
    real(kind=8) ::tol
    integer	 ::nI,v1,v2,v3
    real(kind=8),dimension(0:nx,0:ny,0:nz) :: u,f
    real(kind=8),dimension(:,:,:),allocatable	:: r1 ,r2 ,r3 ,r4 ,r5
    real(kind=8),dimension(:,:,:),allocatable	:: p1 ,p2 ,p3 ,p4 ,p5
    real(kind=8),dimension(:,:,:),allocatable	:: u1 ,u2 ,u3 ,u4 ,u5
    real(kind=8),dimension(:,:,:),allocatable	:: f1 ,f2 ,f3 ,f4 ,f5

    real(kind=8) 			   	:: dx1,dx2,dx3,dx4,dx5
    real(kind=8) 			   	:: dy1,dy2,dy3,dy4,dy5
    real(kind=8) 			   	:: dz1,dz2,dz3,dz4,dz5
    integer				   	:: nx1,nx2,nx3,nx4,nx5
    integer				   	:: ny1,ny2,ny3,ny4,ny5
    integer				   	:: nz1,nz2,nz3,nz4,nz5
    real(kind=8) ::rms0,rms,rmsc

    integer::i,j,k,kiter,ke,me,wl,m

    nI = 100000 !maximum number of outer iteration
    v1 = 2   	!number of relaxation_sor for restriction in V-cycle
    v2 = 2   	!number of relaxation_sor for prolongation in V-cycle
    v3 = 100 	!number of relaxation_sor at coarsest level


    dx1=dx*1.0d0
    dy1=dy*1.0d0
    dz1=dz*1.0d0

    dx2=dx*2.0d0
    dy2=dy*2.0d0
    dz2=dz*2.0d0

    dx3=dx*4.0d0
    dy3=dy*4.0d0
    dz3=dz*4.0d0

    dx4=dx*8.0d0
    dy4=dy*8.0d0
    dz4=dz*8.0d0

    dx5=dx*16.0d0
    dy5=dy*16.0d0
    dz5=dz*16.0d0

    nx1=nx/1
    ny1=ny/1
    nz1=nz/1

    nx2=nx/2
    ny2=ny/2
    nz2=nz/2

    nx3=nx/4
    ny3=ny/4
    nz3=nz/4

    nx4=nx/8
    ny4=ny/8
    nz4=nz/8

    nx5=nx/16
    ny5=ny/16
    nz5=nz/16

    me = 0

    if (nx5.lt.2.or.ny5.lt.2.or.nz5.lt.2) then
        write(*,*)"5 level is high for this grid.."
        stop
    end if



    allocate(u1(0:nx1,0:ny1,0:nz1))
    allocate(f1(0:nx1,0:ny1,0:nz1))
    allocate(r1(0:nx1,0:ny1,0:nz1))
    allocate(p1(0:nx1,0:ny1,0:nz1))

    allocate(u2(0:nx2,0:ny2,0:nz2))
    allocate(f2(0:nx2,0:ny2,0:nz2))
    allocate(r2(0:nx2,0:ny2,0:nz2))
    allocate(p2(0:nx2,0:ny2,0:nz2))

    allocate(u3(0:nx3,0:ny3,0:nz3))
    allocate(f3(0:nx3,0:ny3,0:nz3))
    allocate(r3(0:nx3,0:ny3,0:nz3))
    allocate(p3(0:nx3,0:ny3,0:nz3))

    allocate(u4(0:nx4,0:ny4,0:nz4))
    allocate(f4(0:nx4,0:ny4,0:nz4))
    allocate(r4(0:nx4,0:ny4,0:nz4))
    allocate(p4(0:nx4,0:ny4,0:nz4))

    allocate(u5(0:nx5,0:ny5,0:nz5))
    allocate(f5(0:nx5,0:ny5,0:nz5))
    allocate(r5(0:nx5,0:ny5,0:nz5))
    allocate(p5(0:nx5,0:ny5,0:nz5))

    f1(:,:,:) = f(:,:,:)
    u1(:,:,:) = u(:,:,:)

    !Compute initial resitual:
    call residual(nx1,ny1,nz1,dx1,dy1,dz1,f1,u1,r1)
    !and its l2 norm:
    call l2norm(nx1,ny1,nz1,r1,rms0)

    open(66,file='residual.plt')
    write(66,*) 'variables ="k","rms","rms/rms0"'

    do kiter=1,nI

        !1.Relax v1 times
        do m=1,v1
            call relaxation_sor(nx1,ny1,nz1,dx1,dy1,dz1,f1,u1)			
        end do

        ! Compute residual
        call residual(nx1,ny1,nz1,dx1,dy1,dz1,f1,u1,r1)

        ! Check for convergence on finest grid	
        call l2norm(nx1,ny1,nz1,r1,rms)
        write(66,*) kiter,rms,rms/rms0  
        write(*,*) kiter,rms,rms/rms0 
        if (rms/rms0.le.tol) goto 10

        !1r.Restriction	
        call restriction(nx1,ny1,nz1,nx2,ny2,nz2,r1,f2)

        !Set zero
        do i=0,nx2
        do j=0,ny2
        do k=0,nz2
            u2(i,j,k)=0.0d0
        end do
        end do
        end do


        !2.Relax v1 times
        do m=1,v1
            call relaxation_sor(nx2,ny2,nz2,dx2,dy2,dz2,f2,u2)
        end do

        ! Compute residual
        call residual(nx2,ny2,nz2,dx2,dy2,dz2,f2,u2,r2)

        !2r.Restriction
        call restriction(nx2,ny2,nz2,nx3,ny3,nz3,r2,f3)


        !Set zero
        do i=0,nx3
        do j=0,ny3
	do k=0,nz3
            u3(i,j,k)=0.0d0
        end do
        end do
        end do

        !3.Relax v1 times
        do m=1,v1
            call relaxation_sor(nx3,ny3,nz3,dx3,dy3,dz3,f3,u3)
        end do

        ! Compute residual
        call residual(nx3,ny3,nz3,dx3,dy3,dz3,f3,u3,r3)


        !3r.Restriction
        call restriction(nx3,ny3,nz3,nx4,ny4,nz4,r3,f4)


        !Set zero
        do i=0,nx4
        do j=0,ny4
	do k=0,nz4
            u4(i,j,k)=0.0d0
        end do
        end do
        end do

        !4.Relax v1 times
        do m=1,v1
            call relaxation_sor(nx4,ny4,nz4,dx4,dy4,dz4,f4,u4)
        end do


        ! Compute residual
        call residual(nx4,ny4,nz4,dx4,dy4,dz4,f4,u4,r4)


        !4r.Restriction
        call restriction(nx4,ny4,nz4,nx5,ny5,nz5,r4,f5)


        !Set zero
        do i=0,nx5
        do j=0,ny5
	do k=0,nz5
            u5(i,j,k)=0.0d0
        end do
        end do
        end do

        !5.Relax v3 times (or it can be solved exactly)
        !call initial residual:
	call residual(nx5,ny5,nz5,dx5,dy5,dz5,f5,u5,r5)
	call l2norm(nx5,ny5,nz5,r5,rmsc)
        do m=1,v3
	    call relaxation_sor(nx5,ny5,nz5,dx5,dy5,dz5,f5,u5)
	    call residual(nx5,ny5,nz5,dx5,dy5,dz5,f5,u5,r5)
	    ! Check for convergence on smallest grid	
	    call l2norm(nx5,ny5,nz5,r5,rms)
	    if (rms/rmsc.le.tol) goto 11
        end do
	11 continue

        me = me + m

        !4p.Prolongation
        call prolongation(nx5,ny5,nz5,nx4,ny4,nz4,u5,p4)


        !Correct
        do i=1,nx4-1
        do j=1,ny4-1
        do k=1,nz4-1
            u4(i,j,k) = u4(i,j,k) + p4(i,j,k)
        end do
        end do
        end do

        !4.Relax v2 times
        do m=1,v2
            call relaxation_sor(nx4,ny4,nz4,dx4,dy4,dz4,f4,u4)
        end do

        !3p.Prolongation
        call prolongation(nx4,ny4,nz4,nx3,ny3,nz3,u4,p3)

        !Correct
        do i=1,nx3-1
        do j=1,ny3-1
        do k=1,nz3-1
            u3(i,j,k) = u3(i,j,k) + p3(i,j,k)
        end do
        end do
        end do

        !3.Relax v2 times
        do m=1,v2
            call relaxation_sor(nx3,ny3,nz3,dx3,dy3,dz3,f3,u3)
        end do

        !2p.Prolongation
        call prolongation(nx3,ny3,nz3,nx2,ny2,nz2,u3,p2)


        !Correct
        do i=1,nx2-1
        do j=1,ny2-1
        do k=1,nz2-1
            u2(i,j,k) = u2(i,j,k) + p2(i,j,k)
        end do
        end do
        end do

        !2.Relax v2 times
        do m=1,v2
            call relaxation_sor(nx2,ny2,nz2,dx2,dy2,dz2,f2,u2)
        end do

        !1p.Prolongation
        call prolongation(nx2,ny2,nz2,nx,ny,nz,u2,p1)


        !Correct
        do i=1,nx1-1
        do j=1,ny1-1
        do k=1,nz1-1
            u1(i,j,k) = u1(i,j,k) + p1(i,j,k)
	end do
	end do
	end do

	!1.Relax v2 times
	do m=1,v2
	    call relaxation_sor(nx1,ny1,nz1,dx1,dy1,dz1,f1,u1)
	end do

    end do	! Outer iteration loop

10  continue

    close(66)


    u(:,:,:) = u1(:,:,:)
    ke   = kiter

     

    !work load (total number of operations)
    wl = ke*(v1+v2)*(nx1*ny1*nz1 + nx2*ny2*nz2 + nx3*ny3*nz3 + nx4*ny4*nz4) + me*(nx5*ny5*nz5) 

    write(19,*)"outer number of iteration = ",ke
    write(19,*)"normalized workload       = ",dfloat(wl)/dfloat(nx*ny)
    write(*,*)"outer number of iteration = ",ke
    write(*,*)"normalized workload       = ",dfloat(wl)/dfloat(nx*ny)

    deallocate(u1,f1,r1,p1)
    deallocate(u2,f2,r2,p2)
    deallocate(u3,f3,r3,p3)
    deallocate(u4,f4,r4,p4)
    deallocate(u5,f5,r5,p5)

    return
  
end subroutine multigrid
