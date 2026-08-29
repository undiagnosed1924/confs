#!/usr/bin/perl
use strict;
use warnings;
use LWP::Simple  qw( getstore );
use JSON;
use Data::Dumper;
use File::Basename;
use Digest::MD5    qw( md5_hex );
use LWP::UserAgent qw( );

use Digest::MD5;
use Digest::MD5 qw(md5_hex);

package Deskpool;
use strict;
use warnings;
use JSON;
use LWP::Simple  qw( getstore );
use Data::Dumper;


print imagestorage();



#my $dpfilename = "vzdump-qemu-100-2019_05_28-15_07_38.vma.gz";
#my $dpfilename = "vzdump-qemu-104-2019_06_22-22_51_40.vma.gz";
my $dpfilename = "vzdump-qemu-500-2025_06_14-11_12_48.vma.zst";
my $dpfile = "/var/lib/vz/dump/" . $dpfilename;
my $dpurl = "https://dl.deskpool.com/" . $dpfilename;

my $md5filename = "dpmd5.txt";
my $md5file = "/var/lib/vz/dump/" . $md5filename;
my $md5fileurl = "https://dl.deskpool.com/" . $md5filename;


sub check_md5 {
    my ($file,$md5code) = @_;
    open( FILE, $file ) || die "Can't open '$file':$!";
    binmode(FILE);
    my $md5 = Digest::MD5->new;
    print "    Check $file md5 ...... \n";
    map { $md5->add($_) } <FILE>;
    close(FILE);

    open(DATA,"<$md5code") or die "file.txt 文件无法打开, $!";
    my $md5str = <DATA>;
    close(DATA);
    
    my $md5calc = $md5->hexdigest;
    #print "  $md5calc vs $md5str \n";
    my $result = ($md5str eq $md5calc);
    if ($result)
    {
        print "    Result OK \n";
    }
    else
    { 
        print "    Result Fail \n";
    }
    return $result;
}

sub calc_md5 {
    my ($file,$md5code) = @_;
    print "calc md5 $file $md5code"; 
    open( FILE, $file ) || die "Can't open '$file':$!";
    binmode(FILE);
    my $md5 = Digest::MD5->new;
    map { $md5->add($_) } <FILE>;
    close(FILE);

    open(DATA, ">$md5code") or die "file.txt 文件无法打开, $!";

    #open DATA  $md5code;
    #sysopen(DATA, "testfile.txt", O_RDWR);
    #sysopen(DATA,$md5code,O_CREAT);
    print  DATA $md5->hexdigest; 
    close(DATA);
}


#check_md5($dpfile,$md5file);

#print "calc md5 $dpfile $md5file"; 
#calc_md5($dpfile,$md5file);
#exit;

sub download_dp {
    unlink  $md5file;
    
    print "\nDownload deskpool image ... \n";
    
    #getstore($md5fileurl,$md5file);
    #$md5fileurl = "http://baidu.com"; 
    #getstore($md5fileurl,$md5file);
   
    print "    Get image md5.	".$md5fileurl."\n";
    system("wget","-o","wget.log",$md5fileurl,"--no-check-certificate","-q","--referer=http://www.doracloud.cn/");
    
    if(-e $md5file)
    {
        if(not(-e $dpfile))
        {
            print "    Get image $dpfilename from ".$dpurl." \n";
            system("wget","-o","wget.log", $dpurl, "--no-check-certificate","-q","--show-progress","--referer=http://www.doracloud.cn/");
            sleep(5);
        }
        if((-e $dpfile) and (not(check_md5($dpfile,$md5file))))
        {
            print "    Current image $dpfilename is invalid. delete it.\n";
            unlink $dpfile; 
            print "    Get image $dpfilename from ".$dpurl." \n";
            system("wget","-o","wget.log", $dpurl, "--no-check-certificate","-q","--show-progress","--referer=http://www.doracloud.cn/");
            sleep(5);
            if((-e $dpfile) and (not(check_md5($dpfile,$md5file)))) 
            {
                die  "    Deskpool VM MD5 is not correct. EXIT.\n";
            }
            print "    Image md5 check is OK.\n";
        }
    } 
    else
    {
        die "Can't download deskpool vm MD5 file.\n";
    } 
    
    #print " download deskpool vm failed!\n";
   
    if(-e $dpfile)
    {
    }
    else
    {
        print "    Download deskpool vm failed!\n";
    }
}

sub get_dpvmid {

#    return 888;
    my $vmidstr = `pvesh get /cluster/nextid`;
    #my $vmid = system("pvesh","get","/cluster/nextid");
    my $vmid = $vmidstr + 0;
    
    #print Dumper($vmid);
    print "\nAllocate vmid $vmid to Deskpool VM.\n";
    return $vmid+0;
}


sub imagestorage {
    my $storagelist = decode_json(`pvesh get /storage/ --output-format json`);

    #print Dumper($storagelist);
    #print Dumper($storagelist->[0]);
    foreach my $item (@{$storagelist}) {
        #print $item->{"content"};
        #print $item->{"storage"};

        if ($item->{"content"} =~ 'images')
        {
            return $item->{"storage"};
        }
    }
}

sub restore_dp {
    my ($vmid,$vmfile) = @_;
    print "\nStart restore deskpool backup $vmfile to $vmid.\n";
    #system("qmrestore",$vmfile,$vmid);
    system("qmrestore",$vmfile,  $vmid ,"--storage",imagestorage(),"--unique");

}


sub start_dp {
    my ($vmid) = @_;

    print "\nPower on Deskpool VM $vmid.\n";
    system("qm","start",$vmid);
}

sub ipaddr {
    my ($ifinfo) = @_;

    #print Dumper($ifinfo);
    #print Dumper($ifinfo->[0]);

    foreach my $info (@{$ifinfo} ) {
        #print $info->{"name"} . "\n";
        #print Dumper($info->{"ip-addresses"}) . "\n";
        #print Dumper($info);
        if ($info->{"name"} ne 'lo')
        {
            my @addresses = @{$info->{"ip-addresses"}};
            foreach my $addr (@addresses)
            {
                #print Dumper($addr);
                if($addr->{'ip-address-type'} eq 'ipv4')
                {
                    return $addr->{'ip-address'};
                }
            }
        }
        #print $info->{"name"} . "\n";
        #print Dumper($info);
    }
}

#print "file name " . $dpfile

download_dp();

my $dpvmid = get_dpvmid();

#$dpvmid=100;

#print "deskpool vm id is " . $dpvmid;
#print Dumper($dpvmid);

restore_dp($dpvmid,$dpfile);
start_dp($dpvmid,);

my $json_text = `qm agent $dpvmid network-get-interfaces`;

#print Dumper($json_text);

#$json_text = system("qm","agent",$dpvmid,"network-get-interfaces");
#print "call system qm agent " . $json_text;
print  "Wait Deskpool vm network starting \n";
for(my $idx=0;$idx<30; $idx=$idx+1)
{
    last if(index($json_text,"ip-addresses") >0);
    sleep(5);
    print "..... \n";
    $json_text = `qm agent $dpvmid network-get-interfaces`;
}

sleep(5);
$json_text = `qm agent $dpvmid network-get-interfaces`;

print "\nSuccess! \n\n";

my $json = decode_json($json_text);

my $ip = ipaddr($json);

print "Please access Deskpool by   https://$ip \n";
 
 
