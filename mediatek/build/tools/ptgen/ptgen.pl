#!/usr/local/bin/perl



#****************************************************************************
# Included Modules
#****************************************************************************
use File::Basename;

# arrays save excel field values, now, we are using only 4 columns, Partition, Start, SizeKB, and DL.

my $PARTITION_FIELD ;
my $START_FIELD ;
my $SIZEKB_FIELD ;
my $DL_FIELD ;
my $PARTITION_IDX_FIELD ;

my $SECRO_SIZE;
my $USERDATA_SIZE;
my $SYSTEM_SIZE;
my $CACHE_SIZE;
my $dsp_size_KB = 0;
# Okey, that are the arrays.
my $total_rows = 0 ;



my $os = &OsName();

my $LOCAL_PATH;

BEGIN
{
  $LOCAL_PATH = dirname($0);
}

if ($os eq "linux")
{
   print "Os = linux\n";

   use lib "$LOCAL_PATH/../Spreadsheet";
   use lib "$LOCAL_PATH/../";
   require 'ParseExcel.pm';
   $start_num = 0; 
}
else
{
  die "Only linux is support now!\n";
}

my $DebugPrint    = 1; # 1 for debug; 0 for non-debug

#argv from alps/mediatek/build/makemtk.mk

my $PLATFORM                    = $ARGV[0] ; # MTxxxx
my $LCA_PRJ                     = $ARGV[1] ; # weather is it a LCA project, "yes" or "no"
my $PART_TABLE_FILENAME         = $ARGV[2] ; # excel file name
my $PARTITION_DEFINE_H_NAME     = $ARGV[3] ; # 
my $SCAT_NAME                   = $ARGV[4] ; # 
my $PAGE_SIZE                   = $ARGV[5] ; #
#for emmc
my $EMMC_SUPPORT		= $ARGV[6] ; # weather it support emmc,"yes" or "no"
if ($EMMC_SUPPORT eq "yes") {
    $EMMC_CHIP			= $ARGV[7] ; # a numeric data, ref to chip colume index in emmc_region.xls
    $EMMC_PART_SIZE_LOCATION	= $ARGV[8] ; # where is the EMMC_partition_size.mk which store the partition size
#    $LDVT_SUPPORT		= $ARGV[9] ;
#    $TARGET_BUILD_VARIANT	= $ARGV[10] ;
    $TARGET_BUILD_VARIANT	= $ARGV[9] ;
} else {
    $EMMC_PART_SIZE_LOCATION	= $ARGV[7] ; # where is the EMMC_partition_size.mk which store the partition size
#    $LDVT_SUPPORT		= $ARGV[8] ;
#    $TARGET_BUILD_VARIANT	= $ARGV[9] ;
    $TARGET_BUILD_VARIANT	= $ARGV[8] ;
}

# define for columns
my $COLUMN_PARTITION                = 1 ;
my $COLUMN_TYPE                     = $COLUMN_PARTITION + 1 ;
my $COLUMN_START                    = $COLUMN_TYPE + 1 ;
my $COLUMN_END                      = $COLUMN_START + 1 ;
my $COLUMN_SIZE                     = $COLUMN_END + 1 ;
my $COLUMN_SIZEKB                   = $COLUMN_SIZE + 1 ;
my $COLUMN_SIZE2                    = $COLUMN_SIZEKB + 1 ;
my $COLUMN_SIZE3                    = $COLUMN_SIZE2 + 1 ;
my $COLUMN_DL                       = $COLUMN_SIZE3 + 1 ;
my $COLUMN_PARTITION_IDX            = $COLUMN_DL + 1 ;

my $User_Size_KB;
my $te = lc($PLATFORM);
my $PartInfo="mediatek/platform/"."$te"."/kernel/drivers/dum-char/";
my $PartInfo2="mediatek/platform/"."$te"."/kernel/drivers/mmc-host/";
#my $mbr_offset=10*1024;
my $mbr_offset;

if($EMMC_SUPPORT eq "yes"){
	if($EMMC_PART_SIZE_LOCATION=~/mediatek\/config\/(.*)\/configs\/EMMC_partition_size.mk/){
		$PROJECT=$1;
		print "Project name=$1\n";
	}
	my $EMMC_COMPO			= "mediatek/config/$PROJECT/eMMC_Compo.mk" ;
	if (-e $EMMC_COMPO)
	{
		`chmod 777 $EMMC_COMPO`;
		open (EMMC_COMPO, "$EMMC_COMPO") or &error_handler("Ptgen open $EMMC_COMPO fail!\n", __FILE__, __LINE__);
		my @arry=<EMMC_COMPO>;
		my $index;
		for($index=0;$index < @arry;$index++){
			if($arry[$index]=~/MBR_Start_Address_KB.*=(.*)/)
			{
				$mbr_offset = $1;
				last;
			}
		}
		
	}else{
		print "No $EMMC_COMPO\n";
		$mbr_offset=6*1024;	#6MB
	}
	print "MBR_Start_Address_KB=$mbr_offset\n";
}

#my $EMMC_XLS_FILENAME = 'mediatek/build/tools/ptgen/emmc_region.xls';

print "\nargument:\n" ;
print "@ARGV\n";
print "PLATFORM=$PLATFORM \n" ;
print "LCA_PRJ=$LCA_PRJ \n" ;
print "PART_TABLE_FILENAME=$PART_TABLE_FILENAME \n" ;
print "SCAT_NAME=$SCAT_NAME \n" ;
print "PARTITION_DEFINE_H_NAME=$PARTITION_DEFINE_H_NAME \n" ;
print "EMMC_SUPPORT=$EMMC_SUPPORT\n";
print "EMMC_CHIP= $EMMC_CHIP\n";
print "EMMC_PART_SIZE_LOCATION=$EMMC_PART_SIZE_LOCATION\n";
#print "LDVT_SUPPORT=$LDVT_SUPPORT\n";
print "TARGET_BUILD_VARIANT=$TARGET_BUILD_VARIANT\n";

mkdir($SCAT_NAME) if (!-d $SCAT_NAME);

#out putfile name
if ($LCA_PRJ eq "yes")
{
    $SCAT_NAME = $SCAT_NAME . $PLATFORM ."_Android_scatter_LCA.txt" ;
}
else
{
    if ($EMMC_SUPPORT eq "yes") 
    {
        $SCAT_NAME = $SCAT_NAME . $PLATFORM ."_Android_scatter_emmc.txt" ;
    }
    else 
    {
        $SCAT_NAME = $SCAT_NAME . $PLATFORM ."_Android_scatter.txt" ;
    }
}
$PARTITION_DEFINE_H_NAME = $PARTITION_DEFINE_H_NAME . "/" . "partition_define.h" ;

print "SCAT_NAME=$SCAT_NAME \n" ;
print "PARTITION_DEFINE_H_NAME=$PARTITION_DEFINE_H_NAME \n" ;

my $SHEET_NAME = $PLATFORM ." " . $LCA_PRJ ;
if ($PAGE_SIZE eq "4K")
{
    $SHEET_NAME = $SHEET_NAME . " " . $PAGE_SIZE ;
}

if ($EMMC_SUPPORT eq "yes")
{
    $SHEET_NAME = $SHEET_NAME . " " . "emmc";
}

#if ($LDVT_SUPPORT eq "yes")
#{
#    $SHEET_NAME = $SHEET_NAME . " " . "ldvt";
#}

if($PLATFORM eq "MT6575"){
	if($TARGET_BUILD_VARIANT eq "user")
	{
	$SHEET_NAME = $SHEET_NAME . " " . "user";
	}
	else
	{
	$SHEET_NAME = $SHEET_NAME . " " . "eng";
	}
}
    
print "SHEET_NAME=$SHEET_NAME \n" ;

#****************************************************************************
# main thread
#****************************************************************************
# get already active Excel application or open new
$PartitonBook = Spreadsheet::ParseExcel->new()->Parse($PART_TABLE_FILENAME);

if($EMMC_SUPPORT eq "yes"){
	#&ModifyPartitionTable();
}

&ReadExcelFile () ;

&GenHeaderFile () ;

&GenScatFile () ;

if($PLATFORM eq "MT6573" || $PLATFORM eq "MT6575"){
	&GenDumChar (); #DummyChar
}
if ($EMMC_SUPPORT eq "yes"){
    &EmmcPartInfo();
	&GenMBRFile ();
	&GenPartSizeFile ();
}

print "scatgen done. \n" ;

print "generate:\n$SCAT_NAME\n$PARTITION_DEFINE_H_NAME\n$EMMC_PART_SIZE_LOCATION\n$DummyChar\n/out/MBR EBR1 EBR2\n";

exit ;

#****************************************************************************
# subroutine:  ModifyPartitionTable
# return:      
#****************************************************************************
sub ModifyPartitionTable
{
	my $iter;
	my $Row_Boot1 = 1;
	my $Row_Boot2 = $Row_Boot1+1;
	my $Row_RPMB  = $Row_Boot2+1;
	my $Row_GP1   = $Row_RPMB+1;
	my $Row_GP2   = $Row_GP1+1;
	my $Row_GP3   = $Row_GP2+1;
	my $Row_GP4   = $Row_GP3+1;
	my $Row_User  = $Row_GP4+1;
	
	my $EMMC_REGION_FILENAME = "mediatek/build/tools/ptgen/emmc_region.xls" ; # where is the emmc_region.xls which include the emmc chip info
	print "EMMC_REGION_FILENAME=$EMMC_REGION_FILENAME\n";
	$ChipRegionBook = Spreadsheet::ParseExcel->new()->Parse($EMMC_REGION_FILENAME);
	my $EMMC_SHEET_NAME = 'emmc';
	my $EMMC_sheet = get_sheet($EMMC_SHEET_NAME,$ChipRegionBook) ;	
	if ($EMMC_sheet eq undef){
		print "emmc get_sheet failed? $SHEET_NAME\n" ;
		exit ;
	}

	#emmc chip xls
	my $Boot1_Size_KB = &lin_xls_cell_value($EMMC_sheet, $Row_Boot1, $EMMC_CHIP);
	my $Boot2_Size_KB = &lin_xls_cell_value($EMMC_sheet, $Row_Boot2, $EMMC_CHIP);
	my $RPMB_Size_KB  = &lin_xls_cell_value($EMMC_sheet, $Row_RPMB, $EMMC_CHIP);
	$User_Size_KB = &lin_xls_cell_value($EMMC_sheet, $Row_User, $EMMC_CHIP);
	$mbr_offset = $Boot1_Size_KB + $Boot2_Size_KB + $RPMB_Size_KB;
	print "mbr start is $mbr_offset\n";
}

#****************************************************************************
# subroutine:  ReadExcelFile
# return:      
#****************************************************************************

sub ReadExcelFile
{
    my $sheet;
    my $read  = 1; # if this flag counts to '0', it means End Of Sheet
    
    my $row = 1 ;
    my $size_B = 0;
    my $start = 0;
    
    $sheet = get_sheet($SHEET_NAME,$PartitonBook) ;
    
    if ($sheet eq undef)
    {
        print "get_sheet failed? $SHEET_NAME\n" ;
    }
    
    while ($read)
    {
        $PARTITION_FIELD[$row-1] = &xls_cell_value($sheet, $row, $COLUMN_PARTITION) ;
        $DL_FIELD[$row-1]        = &xls_cell_value($sheet, $row, $COLUMN_DL) ;

        if ($EMMC_SUPPORT eq "yes"){
                $PARTITION_IDX_FIELD[$row-1]        = &xls_cell_value($sheet, $row, $COLUMN_PARTITION_IDX) ;
        }
    
        if ($PARTITION_FIELD[$row-1] eq "END")
        {
#            print "meet END.\n";
            $read = 0 ;
        }
        if ($read)
        {    
	     if($PARTITION_FIELD[$row-1] eq "MBR" && $EMMC_SUPPORT eq "yes"){	
	     	$SIZEKB_FIELD[$row-2]    = $mbr_offset - $START_FIELD[$row-2]/1024;
	     }
	     $SIZEKB_FIELD[$row-1]    = &xls_cell_value($sheet, $row, $COLUMN_SIZEKB) ;

	     if($row-1 == 0){
		    $START_FIELD[$row-1] = 0;	        
	     }else{
        	$START_FIELD[$row-1] =  $start  + $SIZEKB_FIELD[$row-2] * 1024;
	     }
         if($PARTITION_FIELD[$row-1] eq "BMTPOOL")
	     {
			$START_FIELD[$row-1] = &xls_cell_value($sheet, $row, $COLUMN_START) ;				
	      }
			$start = $START_FIELD[$row-1];

	     if($PARTITION_FIELD[$row-1] eq "SEC_RO")
	     {
		$SECRO_SIZE = $SIZEKB_FIELD[$row-1]/1024;				
	      }
	     if($PARTITION_FIELD[$row-1] eq "ANDROID")
	     {
		$SYSTEM_SIZE = $SIZEKB_FIELD[$row-1]/1024;				
	      }
	     if($PARTITION_FIELD[$row-1] eq "CACHE")
	     {
		$CACHE_SIZE = $SIZEKB_FIELD[$row-1]/1024;				
	      }
	     if($PARTITION_FIELD[$row-1] eq "USRDATA")
	     {
		$USERDATA_SIZE = $SIZEKB_FIELD[$row-1]/1024;				
	      }

            if( $PARTITION_FIELD[$row-1] eq undef   || 
                $START_FIELD[$row-1] eq undef       || 
                $SIZEKB_FIELD[$row-1] eq undef      || 
                $DL_FIELD[$row-1] eq undef
              )
            {
                if( $PARTITION_FIELD[$row-1] eq undef   && 
                    $START_FIELD[$row-1] eq undef       && 
                    $SIZEKB_FIELD[$row-1] eq undef      && 
                    $DL_FIELD[$row-1] eq undef
                   )
                {
                    $read = 0 ;
                }
                die "error in excel file row $row!" ;
            }
	   #debug
           my $prit=sprintf("%x",$START_FIELD[$row-1]);
           print "\nPARTITION_FIELD=$PARTITION_FIELD[$row-1],SIZEKB=$SIZEKB_FIELD[$row-1],START_FIELD=$START_FIELD[$row-1](HEX:0x$prit),DL_FIELD=$DL_FIELD[$row-1]" ;
           if ($EMMC_SUPPORT eq "yes"){
               print ", PARTITION_IDX_FIELD=$PARTITION_IDX_FIELD[$row-1]";
           }
           print "\n";
						
           #debug
            $row ++ ;
        }
    }
    
    if ($row == 1)
    {
        die "error in excel file no data!\n" ;
    }
    
    $total_rows = $row - 1 ;
    
    print "$total_rows read.\n" ;
}
#****************************************************************************
# subroutine:  GenHeaderFile
# return:      
#****************************************************************************
sub GenHeaderFile ()
{
    my $iter = 0 ;
    my $temp ;
    open (PARTITION_DEFINE_H_NAME, ">$PARTITION_DEFINE_H_NAME") or &error_handler("PARTITION_DEFINE: file error!", __FILE__, __LINE__);
    print PARTITION_DEFINE_H_NAME &copyright_file_header();

    print PARTITION_DEFINE_H_NAME "\n#ifndef __PARTITION_DEFINE_H__\n#define __PARTITION_DEFINE_H__\n\n" ;
    
    print PARTITION_DEFINE_H_NAME "\n\n\n#define KB  (1024)\n#define MB  (1024 * KB)\n#define GB  (1024 * MB)\n\n" ;

        
    for ($iter=0; $iter<$total_rows; $iter++)
    {
        if($PARTITION_FIELD[$iter] eq "BMTPOOL")
        {
					$temp = "#define PART_SIZE_$PARTITION_FIELD[$iter]\t\t\t(0x$SIZEKB_FIELD[$iter])\n" ;
    			print PARTITION_DEFINE_H_NAME $temp ;
        }
        else
        {
    			$temp = "#define PART_SIZE_$PARTITION_FIELD[$iter]\t\t\t($SIZEKB_FIELD[$iter]*KB)\n" ;
					print PARTITION_DEFINE_H_NAME $temp ;
        }
        
    }
    
    print PARTITION_DEFINE_H_NAME "#define PART_NUM\t\t\t$total_rows\n";    
	print PARTITION_DEFINE_H_NAME "#define MBR_START_ADDRESS_BYTE\t\t\t($mbr_offset*1024)\n\n";    
    
    print PARTITION_DEFINE_H_NAME "\n\n" ;

    print PARTITION_DEFINE_H_NAME "#endif\n" ;
    
    close PARTITION_DEFINE_H_NAME ;
}
#****************************************************************************
# subroutine:  GenScatFile
# return:      
#****************************************************************************
sub GenScatFile ()
{
    
    my $temp;
    my $iter = 0 ;
    open (SCAT_NAME, ">$SCAT_NAME") or &error_handler("SCAT: file error!", __FILE__, __LINE__) ;

    for ($iter=0; $iter<$total_rows; $iter++)
    {   
        if($PARTITION_FIELD[$iter] ne "BMTPOOL"){
	    $START_FIELD[$iter]=sprintf("%x",$START_FIELD[$iter]);
	}

        if ($DL_FIELD[$iter] == 1)
        {
            $temp = "$PARTITION_FIELD[$iter]" ;
        }
        else
        {
            $temp = "__NODL_$PARTITION_FIELD[$iter]" ;
        }

	$temp .= " 0x$START_FIELD[$iter]\n{\n}\n";

        print SCAT_NAME $temp ;
    }
    
    print SCAT_NAME "\n\n" ;
    close SCAT_NAME ;
}

#****************************************************************************************
# subroutine:  GenMBRFile 
# return:      
#****************************************************************************************

sub GenMBRFile {
	#my $eMMC_size_block = $User_Size_KB*1024/512;
	my $iter = 0;
# MBR & EBR table init
#	
#	MBR
#			P1: extend partition, include SECRO & SYS
#			P2:	CACHE
#			P3: DATA
#			P4: VFAT
#	EBR1
#			P5: SECRO
#	EBR2
#			P6: SYS
#
	my $mbr_start;
	my $p1_start_block;
	my $p1_size_block;
	my $p2_start_block;
	my $p2_size_block;
	my $p3_start_block;
	my $p3_size_block;
	my $p4_start_block;
	my $p4_size_block;
	my $p5_start_block;
	my $p5_size_block;
	my $p6_start_block;
	my $p6_size_block;

my @BR = (
	["mediatek/source/misc/MBR", [	[0x5,	0x0,0x0],
						[0x83,0x0,0x0],
						[0x83,0x0,0x0],
						[0xb,	0x0,0x0]]],
	["mediatek/source/misc/EBR1", [[0x83,0x0,0x0],
						[0x05,0x0,0x0]]],
	["mediatek/source/misc/EBR2", [[0x83,0x0,0x0]]]
);

    $sheet = get_sheet($SHEET_NAME,$PartitonBook) ;
# Fill MBR & EBR table -----------------------------------------------------
	for ($iter=1; $iter<$total_rows+1; $iter++) {   
		if($PARTITION_FIELD[$iter-1] eq "MBR"){
			$mbr_start = hex($START_FIELD[$iter-1]);
		}
		if($PARTITION_FIELD[$iter-1] eq "CACHE"){
			$p2_start_block = (hex($START_FIELD[$iter-1])-$mbr_start)/512;
			$p2_size_block =  ($SIZEKB_FIELD[$iter-1]-1024)*1024/512;
		}
		if($PARTITION_FIELD[$iter-1] eq "USRDATA"){
			$p3_start_block = (hex($START_FIELD[$iter-1])-$mbr_start)/512;
			$p3_size_block =  ($SIZEKB_FIELD[$iter-1]-1024)*1024/512;
		}
		if($PARTITION_FIELD[$iter-1] eq "SEC_RO"){
			$p5_start_block = (hex($START_FIELD[$iter-1])-$mbr_start)/512;
			$p5_size_block =  ($SIZEKB_FIELD[$iter-1]-1024)*1024/512;
		}
		if($PARTITION_FIELD[$iter-1] eq "ANDROID"){
			$p6_start_block = (hex($START_FIELD[$iter-1])-$mbr_start)/512;
			$p6_size_block =  ($SIZEKB_FIELD[$iter-1]-1024)*1024/512;
		}
	}
	#MBR
	print "MBR start is $mbr_start\n";
	$BR[0][1][0][1] = $p1_start_block = 0x20;
	$BR[0][1][1][1] = $p2_start_block;
	$BR[0][1][2][1] = $p3_start_block;
	$BR[0][1][3][1] = $p4_start_block = $p3_start_block + $p3_size_block+2048;#0xCEF20;
	print "P1 start is $p1_start_block\n";
	print "P2 start is $p2_start_block\n";
	print "P3 start is $p3_start_block\n";
	print "P4 start is $p4_start_block\n";
	$BR[0][1][0][2] = $p1_size_block = $p2_start_block - $p1_start_block;
	$BR[0][1][1][2] = $p2_size_block;
	$BR[0][1][2][2] = $p3_size_block;
	#$BR[0][1][3][2] = $p4_size_block = $eMMC_size_block -$p4_start_block;
	$BR[0][1][3][2] = $p4_size_block =0xffffffff;
	print "P1 size is $p1_size_block\n";
	print "P2 size is $p2_size_block\n";
	print "P3 size is $p3_size_block\n";
	print "P4 size is $p4_size_block\n";
	#print "eMMC size is $eMMC_size_block\n";

	print "P5 start is $p5_start_block\n";
	print "P5 size is $p5_size_block\n";
	print "P6 start is $p6_start_block\n";
	print "P6 size is $p6_size_block\n";
	#EBR1
	$BR[1][1][0][1] = $p5_start_block - $p1_start_block;
	$BR[1][1][0][2] = $p5_size_block;
	$BR[1][1][1][1] = $p6_start_block - 0x20 - 0x20;
	$BR[1][1][1][2] = $p6_size_block + 0x20;

	#EBR2
	$BR[2][1][0][1] = 0x20;
	$BR[2][1][0][2] = $p6_size_block;

# Generate MBR&EBR binary file -----------------------------------------------------
foreach my $sBR (@BR){
	print("Generate $sBR->[0] bin file\n");
	
	#create file
	open(FH,">$sBR->[0]")|| die "create $sBR->[0] file failed\n";
	print FH pack("C512",0x0);

	#seek to tabel
	seek(FH,446,0);

	foreach (@{$sBR->[1]}){
		#type
		seek(FH,4,1);
		print FH pack("C1",$_->[0]);
		#offset and length
		seek(FH,3,1);
		print FH pack("I1",$_->[1]);
		print FH pack("I1",$_->[2]);
	}
	
	#end label
	seek(FH,510,0);
	print FH pack("C2",0x55,0xAA);

	close(FH);
}

}

#****************************************************************************************
# subroutine:  GenPartSizeFile;
# return:      
#****************************************************************************************

sub GenPartSizeFile
{
	my $temp;
	`chmod 777 $EMMC_PART_SIZE_LOCATION` if (-e $EMMC_PART_SIZE_LOCATION);
        open (EMMC_PART_SIZE_LOCATION, ">$EMMC_PART_SIZE_LOCATION") or &error_handler("CAN NOT open $EMMC_PART_SIZE_LOCATION", __FILE__, __LINE__) ;
        `chmod 777 $EMMC_PART_SIZE_LOCATION` if (-e $EMMC_PART_SIZE_LOCATION);
	my $header = "\#!/usr/local/bin/perl
\# Copyright Statement:
\# This software/firmware and related documentation (\"MediaTek Software\") are
\# protected under relevant copyright laws. The information contained herein
\# is confidential and proprietary to MediaTek Inc. and/or its licensors.
\# Without the prior written permission of MediaTek inc. and/or its licensors,
\# any reproduction, modification, use or disclosure of MediaTek Software,
\# and information contained herein, in whole or in part, shall be strictly prohibited.
\#
\# MediaTek Inc. (C) 2010. All rights reserved.
\#
\# BY OPENING THIS FILE, RECEIVER HEREBY UNEQUIVOCALLY ACKNOWLEDGES AND AGREES
\# THAT THE SOFTWARE/FIRMWARE AND ITS DOCUMENTATIONS (\"MEDIATEK SOFTWARE\")
\# RECEIVED FROM MEDIATEK AND/OR ITS REPRESENTATIVES ARE PROVIDED TO RECEIVER ON
\# AN \"AS-IS\" BASIS ONLY. MEDIATEK EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES,
\# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
\# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NONINFRINGEMENT.
\# NEITHER DOES MEDIATEK PROVIDE ANY WARRANTY WHATSOEVER WITH RESPECT TO THE
\# SOFTWARE OF ANY THIRD PARTY WHICH MAY BE USED BY, INCORPORATED IN, OR
\# SUPPLIED WITH THE MEDIATEK SOFTWARE, AND RECEIVER AGREES TO LOOK ONLY TO SUCH
\# THIRD PARTY FOR ANY WARRANTY CLAIM RELATING THERETO. RECEIVER EXPRESSLY ACKNOWLEDGES
\# THAT IT IS RECEIVER'S SOLE RESPONSIBILITY TO OBTAIN FROM ANY THIRD PARTY ALL PROPER LICENSES
\# CONTAINED IN MEDIATEK SOFTWARE. MEDIATEK SHALL ALSO NOT BE RESPONSIBLE FOR ANY MEDIATEK
\# SOFTWARE RELEASES MADE TO RECEIVER'S SPECIFICATION OR TO CONFORM TO A PARTICULAR
\# STANDARD OR OPEN FORUM. RECEIVER'S SOLE AND EXCLUSIVE REMEDY AND MEDIATEK'S ENTIRE AND
\# CUMULATIVE LIABILITY WITH RESPECT TO THE MEDIATEK SOFTWARE RELEASED HEREUNDER WILL BE,
\# AT MEDIATEK'S OPTION, TO REVISE OR REPLACE THE MEDIATEK SOFTWARE AT ISSUE,
\# OR REFUND ANY SOFTWARE LICENSE FEES OR SERVICE CHARGE PAID BY RECEIVER TO
\# MEDIATEK FOR SUCH MEDIATEK SOFTWARE AT ISSUE.
\#
\# The following software/firmware and/or related documentation (\"MediaTek Software\")
\# have been modified by MediaTek Inc. All revisions are subject to any receiver's
\# applicable license agreements with MediaTek Inc.
\#
\#
";

	print EMMC_PART_SIZE_LOCATION $header;
	$temp = "ifeq (\$(MTK_EMMC_SUPPORT),yes)\n";
	print EMMC_PART_SIZE_LOCATION $temp ;
	$SECRO_SIZE = $SECRO_SIZE -1;
	$temp = "BOARD_SECROIMAGE_PARTITION_SIZE:=$SECRO_SIZE". "M\n";
	print EMMC_PART_SIZE_LOCATION $temp ;
	$USERDATA_SIZE=$USERDATA_SIZE-1;
	$temp = "BOARD_USERDATAIMAGE_PARTITION_SIZE:=$USERDATA_SIZE"."M\n";
	print EMMC_PART_SIZE_LOCATION $temp ;
	$SYSTEM_SIZE=$SYSTEM_SIZE-1;
	$temp = "BOARD_SYSTEMIMAGE_PARTITION_SIZE:=$SYSTEM_SIZE"."M\n";
	print EMMC_PART_SIZE_LOCATION $temp ;
	$CACHE_SIZE=$CACHE_SIZE-1;
	$temp = "BOARD_CACHEIMAGE_PARTITION_SIZE:=$CACHE_SIZE"."M\n";
	print EMMC_PART_SIZE_LOCATION $temp ;
 	print EMMC_PART_SIZE_LOCATION "endif \n" ;
    	close EMMC_PART_SIZE_LOCATION ;
}

#****************************************************************************************
# subroutine:  GenDumChar
# return:      
#****************************************************************************************

sub GenDumChar ()
{
	my $temp;
	my $iter;
	my $t;
	my $PartInfoC = "$PartInfo"."part_info.c" ;
	my $PartInfoH = "$PartInfo"."part_info.h";
	
	if (-e $PartInfoC)
	{
		`chmod 777 $PartInfoC`;
	}
	open (PartInfoC, ">$PartInfoC") or &error_handler("CAN NOT open $PartInfoC", __FILE__, __LINE__) ;
	print PartInfoC &copyright_file_header();
	$temp = "\#include \"dumchar.h\"\n\#include \"part_info.h\"\nstruct excel_info PartInfo[PART_NUM]={\n";	
	for ($iter=0; $iter<$total_rows; $iter++)
    	{
    	$t = lc($PARTITION_FIELD[$iter]);
	$temp .= "\t\t\t{\"$t\",";
	$t = ($SIZEKB_FIELD[$iter])*1024;
		$temp .= "$t,0x$START_FIELD[$iter]";
		
		if($EMMC_SUPPORT eq "yes"){
		   $t = ($PARTITION_IDX_FIELD[$iter]);
		   $temp .= ",$t";
		}   
		$temp .= "},\n";
	}
 	$temp .= " };\n\nEXPORT_SYMBOL(PartInfo);\n";
	print PartInfoC $temp ;
   	close PartInfoC ;

	if (-e $PartInfoH)
	{
		`chmod 777 $PartInfoH`;
	}
	open (PartInfoH, ">$PartInfoH") or &error_handler("CAN NOT open $PartInfoH", __FILE__, __LINE__) ;
	print PartInfoH &copyright_file_header();
	$temp = "\#ifndef __PARTINFO_H__\n\#define __PARTINFO_H__\n";
	$temp .= "\#define PART_NUM\t$total_rows\n\#endif\n";
	print PartInfoH $temp;
	print PartInfoH "#define MBR_START_ADDRESS_BYTE\t\t\t($mbr_offset*1024)\n\n"; 
	close PartInfoH;   	
}

#****************************************************************************************
# subroutine:  GenEmmcPartInfo
# return:      
#****************************************************************************************

sub EmmcPartInfo()
{
	my $temp;
	my $iter;
	my $t;
	my $PartInfoC = "$PartInfo2"."part_info_emmc.c" ;
	my $PartInfoH = "$PartInfo2"."part_info_emmc.h";
	
	if (-e $PartInfoC)
	{
		`chmod 777 $PartInfoC`;
	}
	open (PartInfoC, ">$PartInfoC") or &error_handler("CAN NOT open $PartInfoC", __FILE__, __LINE__) ;
	print PartInfoC &copyright_file_header();
	$temp = "\#include \"part_info_emmc.h\"\nstruct excel_info PartInfoEmmc[PART_NUM]={\n";	
	for ($iter=0; $iter<$total_rows; $iter++)
    	{
    	$t = lc($PARTITION_FIELD[$iter]);
	$temp .= "\t\t\t{\"$t\",";
	$t = ($SIZEKB_FIELD[$iter])*1024;
		$temp .= "$t,0x$START_FIELD[$iter]";
		
		if($EMMC_SUPPORT eq "yes"){
		   $t = ($PARTITION_IDX_FIELD[$iter]);
		   $temp .= ",$t";
		}   
		$temp .= "},\n";
	}
    $temp .= " };\n";
	print PartInfoC $temp ;
   	close PartInfoC ;

	if (-e $PartInfoH)
	{
		`chmod 777 $PartInfoH`;
	}
	open (PartInfoH, ">$PartInfoH") or &error_handler("CAN NOT open $PartInfoH", __FILE__, __LINE__) ;
	print PartInfoH &copyright_file_header();
    #$temp = "\#ifndef __EMMCPARTINFO_H__\n\#define __EMMCPARTINFO_H__\n";
	$temp = "\#ifndef __EMMCPARTINFO_H__\n\#define __EMMCPARTINFO_H__\n\ struct excel_info{\n\    char * name;\n    unsigned int size;\n    unsigned int start_address;\n};\n";
	$temp .= "\#define PART_NUM\t$total_rows\n\#endif\n";
	print PartInfoH $temp;
	close PartInfoH;   	
}



#****************************************************************************
# subroutine:  error_handler
# input:       $error_msg:     error message
#****************************************************************************
sub error_handler
{
	   my ($error_msg, $file, $line_no) = @_;
	   
	   my $final_error_msg = "scatgen ERROR: $error_msg at $file line $line_no\n";
	   print $final_error_msg;
	   die $final_error_msg;
}

#****************************************************************************
# subroutine:  copyright_file_header
# return:      file header -- copyright
#****************************************************************************
sub copyright_file_header
{
    my $template = <<"__TEMPLATE";
__TEMPLATE

   return $template;
}

#****************************************************************************************
# subroutine:  OsName
# return:      which os this script is running
# input:       no input
#****************************************************************************************
sub OsName {
  my $os = `set os`;
  if(!defined $os) { 
    $os = "linux";
  } 
  else {
    die "does not support windows now!!" ;
    $os = "windows";
  }
}
#*************************************************************************************************
# subroutine:  gen_pm
# return:      no return, but will generate a ForWindows.pm in "/perl/lib" where your perl install
#*************************************************************************************************
sub gen_pm {
  foreach (@INC) {
    if(/^.*:\/Perl\/lib$/) {
      open FILE, ">${_}\/ForWindows.pm";
      print FILE "package ForWindows;\n";
      print FILE "use Win32::OLE qw(in with);\n";
      print FILE "use Win32::OLE::Const 'Microsoft Excel';\n";
      print FILE "\$Win32::OLE::Warn = 3;\n";
      print FILE "1;";
      close(FILE);
      last;
    }
  }
}
#****************************************************************************************
# subroutine:  get_sheet
# return:      Excel worksheet no matter it's in merge area or not, and in windows or not
# input:       Specified Excel Sheetname
#****************************************************************************************
sub get_sheet {
  my ($sheetName,$Book) = @_;
  if ($os eq "windows") {
    return $Sheet     = $Book->Worksheets($sheetName);
  }
  else {
    return $Sheet     = $Book->Worksheet($sheetName);
  }
}


#****************************************************************************************
# subroutine:  xls_cell_value
# return:      Excel cell value no matter it's in merge area or not, and in windows or not
# input:       $Sheet:  Specified Excel Sheet
# input:       $row:    Specified row number
# input:       $col:    Specified column number
#****************************************************************************************
sub xls_cell_value {
  my ($Sheet, $row, $col) = @_;
  if ($os eq "windows") {
    return &win_xls_cell_value($Sheet, $row, $col);
  }
  else {
      return &lin_xls_cell_value($Sheet, $row, $col);
  }
}
sub win_xls_cell_value
{
    my ($Sheet, $row, $col) = @_;

    if ($Sheet->Cells($row, $col)->{'MergeCells'})
    {
        my $ma = $Sheet->Cells($row, $col)->{'MergeArea'};
        return ($ma->Cells(1, 1)->{'Value'});
    }
    else
    {
        return ($Sheet->Cells($row, $col)->{'Value'})
    }
}
sub lin_xls_cell_value
{
  my ($Sheet, $row, $col) = @_;
  my $cell = $Sheet->get_cell($row, $col);
  exit 1 unless (defined $cell);
  my $value = $cell->Value();

}
