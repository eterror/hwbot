all: hw plugin
zip: clean compress

hw: hw.pp geoip.pp hwTypes.pp hwObjects.pp
	fpc geoip.pp
	fpc hwTypes.pp
	fpc hwObjects.pp
	fpc hw.pp

plugin: plugins/*.pp
	fpc plugins/note.pp
	fpc plugins/memo.pp
	fpc plugins/seen.pp
	fpc plugins/counter.pp
	fpc plugins/uptime.pp
	fpc plugins/who.pp

clean:
	rm -rf *.o
	rm -rf *.ppu
	rm -rf plugins/*.o
	rm -rf plugins/*.so
	
compress:
	rm -rf *.tar.gz
	tar -cvzf hwInfobot-$(shell grep VERSION hwTypes.pp|grep rc |cut -d '=' -f 2|sed s/\'//g|sed s/\;//g|sed s/" "//g).tar.gz ../$(shell basename `pwd`)

