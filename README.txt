%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   MULTIMEDIA DATA SECURITY COURSE                     %
%                                                       %
%   2° PROJECT/COMPETITION                              %
%                                                       %
%   Group name: Crazy                                   %
%   members:    Kristjan Gjika                          %
%               Abdullah M. R. Alhamdan                 %
%               Berioshka C. Vargas                     %
%                                                       %
%   Project carried out for the Euregio challenge       %    
%                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


README file

Environment: 
============

    - MATLAB R2017b
        - Add-on: 
                1. Image Processing Toolbox
                2. Wavelets Based Denoising

    - Windows 10

Sintax: 
=======

    [name_output] = get_map(name_file)
    
    - name_file:    path + name file for which you ask for forgering detection
    - name_output:  path + name file of the bitmap image 


Clarifications:
===============

The function run under matlab environment, the Add-on 2 is required for the 
complete computation of all strategies of detctions. Is not necessary for a
partial working of the function. The add-on was not provider because it's
manual compilation give error, but the the compilation internal of matlab 
work well.

The function was tested under Windows 10, no test are made under Linux or 
MacOS, anyway there all the precompiled support function for linux as well 
but not tested. We prefer to do it 

The function will save the image into the folder RESULTS with the same name
of the input image but different extension, as required the extension will
be *.bmp .

The function is programmed for creating a log file, debug_output.txt of all
the operation that are performed. If there are malfunction we ask you to 
give us the log file to understand what was go wrong. 

For computation requirment the function will write some test image into the
folder SUPPORT/tmp, those image are NOT deleted after completing the detection.

There are not needed other initial configuration, all the necessary path are
set by the function.

====================
Setting up the tool
====================
Before using the tool, please do the following!: 
1- UNZIP SUPPORT_01.zip BEFORE and rename it to "SUPPORT"!
2- Download the camera's data file using the following link, after that, please add the folder as a subfolder to SUPPORT, sorry for such complicated stuff, but each camera signature is more than the file size limit! the link is:  
https://drive.google.com/open?id=1PNVVn0j4DwpgwrVEOiYYeEa7h-8_CUVg

