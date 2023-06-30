F90  = mpif90
RM  = rm -f

FFLAGS    = -O3 -mp=gpu -Minfo=mp -gpu=cc80 -cpp
#FFLAGS    = -O3 -noacc -cpp
LDFLAGS   = 

SRCS   = misc.f90 diffusion.f90 main.f90
TARGET = ompgpu_nowait_overlap
DISTTARGET = $(TARGET)_1.0.0

OBJS += $(filter %.o,$(SRCS:%.f90=%.o))


.PHONY: all
all : $(TARGET)

$(TARGET) : $(OBJS)
	$(F90) $(FFLAGS) $(TARGET_ARCH) $(OBJS) -o $@ $(LDFLAGS)

%.o : %.f90
	$(F90) $(FFLAGS) $(TARGET_ARCH) -c $<


.PHONY: clean
clean :
	$(RM) $(TARGET)
	$(RM) $(OBJS)
	$(RM) *.mod
	$(RM) *~


