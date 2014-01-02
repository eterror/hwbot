unit geoip;

interface
    
{function setpathtodb():boolean;}
function getip(a, b, c, d: Cardinal):string;    


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
    
    assign(f, 'ip.db');
    {$I-}reset(f);{$I+}
    
    if (IOResult <> 0) then
	exit;
    
    n:=ip2dec(a, b, c, d);
    
    while not (eof(f)) do
    begin
	readln(f, line);
	ip:=copy(line, 1, pos(#32, line)-1);
	country:=copy(line, pos(#32, line)+1, length(line));
	
	if (IntToStr(n) = ip) then
	begin
	    getip:=country;
	    break;
	end;
    end;
    
    close(f);
end;


begin
end.