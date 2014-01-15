all: hw plugin
zip: clean compress

FPCFLAGS = -Sc -v0

ifeq ($(UNAME_P),x86_64)
    FPCFLAGS +=  -fPIC
endif

#$(info Compiler flags: $(FPCFLAGS))

hw: hw.pp geoip.pp hwTypes.pp hwObjects.pp
	fpc $(FPCFLAGS) geoip.pp
	fpc $(FPCFLAGS) hwTypes.pp
	fpc $(FPCFLAGS) hwObjects.pp
	fpc $(FPCFLAGS) hw.pp

plugin: plugins/*.pp
	fpc $(FPCFLAGS) plugins/note.pp
	fpc $(FPCFLAGS) plugins/memo.pp
	fpc $(FPCFLAGS) plugins/seen.pp
	fpc $(FPCFLAGS) plugins/counter.pp
	fpc $(FPCFLAGS) plugins/uptime.pp
	fpc $(FPCFLAGS) plugins/who.pp
#	fpc $(FPCFLAGS) plugins/translate.pp

clean:
	rm -rf *.o
	rm -rf *.ppu
	rm -rf plugins/*.o
	rm -rf plugins/*.so
	
compress:
	rm -rf *.tar.gz
	tar -cvzf hwInfobot-$(shell grep VERSION hwTypes.pp|grep rc |cut -d '=' -f 2|sed s/\'//g|sed s/\;//g|sed s/" "//g).tar.gz ../$(shell basename `pwd`)

