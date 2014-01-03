(*
 * simple unit for geolocalization by solaris (solargrim@gmail.com)
 * 
 * TODO: Change database to fresh
*)

{$MODE OBJFPC}

unit geoip;

interface
    
{function setpathtodb():boolean;}
function getip(a, b, c, d: Cardinal):string;    
function getCountry(src: String):String; deprecated;

implementation

uses sysutils,linux;

var
    f: text;
    line: string;
    n: Cardinal;
    
    ip, country: String;
    
    
function ip2dec(a, b, c, d: Cardinal):Cardinal;
begin
    a *= 16777216;
    b *= 65536;
    c *= 256;
    
    ip2dec:=a+b+c+d;
end;
    

function getip(a, b, c, d: Cardinal):string;
begin
    getip:='Unknown';
    
    assign(f, 'plugins/ip.db');
    {$I-}reset(f);{$I+}
    
    if (IOResult <> 0) then
	exit;
    
    n:=ip2dec(a, b, c, d);
    
    while not (eof(f)) do
    begin
	readln(f, line);
	ip:=copy(line, 1, pos(#32, line)-1);
	country:=copy(line, pos(#32, line)+1, length(line));
	
	try
	    if (IntToStr(n) = ip) then
	    begin
		getip:=country;
		break;
	    end;
	except
	end;
    end;
    
    close(f);
end;


function getCountry(src: String):String; deprecated;
begin
    src[1]:=' ';
    src[length(src)]:=' ';
    src[length(src)-1]:=' ';
    src[length(src)-2]:=' ';
    src[length(src)-3]:=' ';
    src[length(src)-4]:=' ';
    src:=trim(src);

    try
    getCountry:=geoip.getIP(StrToInt(copy(src, 1, pos('.',src)-1)),
                            StrToInt(copy(src, pos('.',src)+1,length(src))),0, 0);

    if (getCountry = 'Unknown') then
        getCountry:=geoip.getIP( StrToInt(copy(src, 1, pos('.',src)-1)),0, 0, 0);

    {...}
    if (getCountry = 'Unknown') then
        getCountry:=geoip.getIP( 0,StrToInt(copy(src, pos('.',src)+1,length(src))),0, 0);
    except
	getCountry:='Unknown';
    end;
end;


begin
end.
