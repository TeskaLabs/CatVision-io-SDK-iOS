CFLAGS+=-O2 -fPIC -I libvncserver/libvncserver -I libvncserver -I libvncserver/common -I . -I libpng -I jpeg

OBJS=\
	libvncserver/libvncserver/auth.o \
	libvncserver/libvncserver/cargs.o \
	libvncserver/libvncserver/corre.o \
	libvncserver/libvncserver/cursor.o \
	libvncserver/libvncserver/cutpaste.o \
	libvncserver/libvncserver/draw.o \
	libvncserver/libvncserver/font.o \
	libvncserver/libvncserver/hextile.o \
	libvncserver/libvncserver/httpd.o \
	libvncserver/libvncserver/main.o \
	libvncserver/libvncserver/rfbregion.o \
	libvncserver/libvncserver/rfbserver.o \
	libvncserver/libvncserver/rre.o \
	libvncserver/libvncserver/scale.o \
	libvncserver/libvncserver/selbox.o \
	libvncserver/libvncserver/sockets.o \
	libvncserver/libvncserver/stats.o \
	libvncserver/libvncserver/tight.o \
	libvncserver/libvncserver/translate.o \
	libvncserver/libvncserver/ultra.o \
	libvncserver/libvncserver/zlib.o \
	libvncserver/libvncserver/zrle.o \
	libvncserver/libvncserver/zrleoutstream.o \
	libvncserver/libvncserver/zrlepalettehelper.o \
	libvncserver/common/d3des.o \
	libvncserver/common/minilzo.o \
	libvncserver/common/sha1.o \
	libvncserver/common/turbojpeg.o \
	libvncserver/common/vncauth.o \
	jpeg/jaricom.o \
	jpeg/jcapimin.o \
	jpeg/jcapistd.o \
	jpeg/jcarith.o \
	jpeg/jccoefct.o \
	jpeg/jccolor.o \
	jpeg/jcdctmgr.o \
	jpeg/jchuff.o \
	jpeg/jcinit.o \
	jpeg/jcmainct.o \
	jpeg/jcmarker.o \
	jpeg/jcmaster.o \
	jpeg/jcomapi.o \
	jpeg/jcparam.o \
	jpeg/jcprepct.o \
	jpeg/jcsample.o \
	jpeg/jctrans.o \
	jpeg/jdapimin.o \
	jpeg/jdapistd.o \
	jpeg/jdarith.o \
	jpeg/jdatadst.o \
	jpeg/jdatasrc.o \
	jpeg/jdcoefct.o \
	jpeg/jdcolor.o \
	jpeg/jddctmgr.o \
	jpeg/jdhuff.o \
	jpeg/jdinput.o \
	jpeg/jdmainct.o \
	jpeg/jdmarker.o \
	jpeg/jdmaster.o \
	jpeg/jdmerge.o \
	jpeg/jdpostct.o \
	jpeg/jdsample.o \
	jpeg/jdtrans.o \
	jpeg/jerror.o \
	jpeg/jfdctflt.o \
	jpeg/jfdctfst.o \
	jpeg/jfdctint.o \
	jpeg/jidctflt.o \
	jpeg/jidctfst.o \
	jpeg/jidctint.o \
	jpeg/jquant1.o \
	jpeg/jquant2.o \
	jpeg/jutils.o \
	jpeg/jmemmgr.o\
	libpng/png.o \
	libpng/pngerror.o \
	libpng/pngget.o \
	libpng/pngmem.o \
	libpng/pngpread.o \
	libpng/pngread.o \
	libpng/pngrio.o \
	libpng/pngrtran.o \
	libpng/pngrutil.o \
	libpng/pngset.o \
	libpng/pngtrans.o \
	libpng/pngwio.o \
	libpng/pngwrite.o \
	libpng/pngwtran.o \
	libpng/pngwutil.o \

all: libvncserver.a

clean:
	rm -rf libvncserver.a ${OBJS}

libvncserver.a: ${OBJS}
	@echo " [AR]" $@
	@$(AR) rcs $@ $^

rebuild: clean all
