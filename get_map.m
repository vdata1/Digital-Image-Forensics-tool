function [name_out] = get_map(namefile)

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
%%
%setup correctly all the paths
addpath('SUPPORT/');
setup

%load the camera model
camera{1} = load('data/camera_models/camera1');
camera{2} = load('data/camera_models/camera2');
camera{3} = load('data/camera_models/camera3');
camera{4} = load('data/camera_models/camera4');

%laod the image and control that the loading fase was done correctly
%some time the function read 4 dimension
image = imread(namefile);
path_tmp = 'SUPPORT/tmp/';
path_result = 'RESULTS/';

make_JPG = true;
make_CFA = false;
make_PRNU = false;
make_other = false;

[ n, m, volume] = size(image);
if volume == 4
    im_nuova(:, :, 1) = image(:, :, 1);
    im_nuova(:, :, 2) = image(:, :, 2);
    im_nuova(:, :, 3) = image(:, :, 3);
    image = im_nuova;
end

%open debug file
debug = fopen('debug_output.txt', 'a');

%list_corr = zeros(1,4);

%%

%prepare the names and a image write in jpeg

supp = strsplit(namefile, '/');

file_name = supp{numel(supp)};

name = strsplit(file_name, '.');
main_name = '';

for t = 1:(numel(name)-1)
    main_name = [main_name name{t}];
end

QF = 85;

%attend to write the image

name_image = [path_tmp main_name '.jpg'];
fprintf(debug, '\n\n ********************************************** \n');
fprintf(debug, ['START at: ' datestr(datetime('now')) '\n']);
fprintf(debug, ['Starting processing image ' main_name ' \n\n']);
try
    imwrite(image, name_image, 'Quality', QF);
catch
    fprintf(debug, ['Error when is attemp to write a jpg image in the path ' path_tmp '\n']);
    fprintf(debug, ['Name file: ' name_image '\n']);
    make_JPG = false;
end
result_name = [path_result main_name '.bmp'];

%%
%first jpeg controll
%read the image only if we write it correctly
if make_JPG
    
    fprintf(debug, 'Starting processing JPEG traces localization \n');
    %get the map for the estimation
    try
        im = jpeg_read(name_image);
        [LLRmap, LLRmap_s, q1table, alphat] = getJmap_EM(im, 1, 6);
        map_final = imfilter(sum(LLRmap,3), ones(3), 'symmetric', 'same');

        %binarize the map
        fin = map_final < -45;

        %get the sum and if it is < 1000 the method has fail
        %must pass to another method
        somma_jpeg = sum(fin(:) == 1);
        [x, y] = size(fin);
        max_map_jpeg = x * y;

        if somma_jpeg < 1000 || (max_map_jpeg - somma_jpeg) < 1000
            make_CFA = true;
            fprintf(debug, 'FAIL: JPEGloc fail for not minimum treshold, passing to CFA \n');
        else
            fprintf(debug, ['Image ' main_name ' computed with JPEGloc \n']);
            fin = mapCleanup(fin, 64);
            %fin = imfill(fin, 'holes');
            fin = imresize(fin, [1500 2000]);
            imwrite(fin, result_name, 'bmp');
            name_out = result_name;
        end
    catch
        fprintf(debug, 'FATAL: during JPEGloc fatal error appear, maybe the function jpeg_read not working \n');
        fprintf(debug, 'FATAL: passing to CFA \n');
        make_CFA = true;
    end
end

%%
%testing with CFA 

if make_CFA
    fprintf(debug, 'Starting processing CFA interpolation localization \n');
    try
        bayer = [0, 1; 1, 0];

        [map, stat] = CFAloc(image, bayer, 8, 2);
        fin = map < 0;
        somma_CFA = sum(fin(:) == 1);
        [x, y] = size(fin);
        max_map_CFA = x * y;
 
        if somma_CFA < 600 || (max_map_CFA - somma_CFA) < 600 
            fprintf(debug, 'FAIL: CFAloc fail for not minimum treshold, passing to PRNU \n');
            make_PRNU = true;
        else
            fprintf(debug, ['Image ' main_name ' computed with CFAloc \n']);
            fin = mapCleanup(fin, 64);
            %fin = imfill(fin, 'holes');
            fin = imresize(fin, [1500 2000]);
            imwrite(fin, result_name, 'bmp');
            name_out = result_name;
        end
    catch
        fprintf(debug, 'FATAL: Attemp to make CFA localizazion, fatal exception occour, maybe for immaginari number \n');
        fprintf(debug, 'FATAL: passing to PRNU \n');
        make_PRNU = true;
    end
end

%%
%testing PRNU

if make_PRNU
    fprintf(debug, 'Starting processing PRNU correlation localization \n');
    try
        
        noise_sigma = 3.0;
        list_corr = zeros(1,4);
        %find the correspondence of the camera if exist
        %extraxt the first noise
        noise = NoiseExtractFromImage(image, noise_sigma);
        noise = ZeroMeanTotal(noise);
        noise = WienerInDFT(noise, std2(noise));

        image2 = double(rgb2gray(image));

        %find the most suitable correlation 
        for pr = 1 : numel(camera)
            prnu = rgb2gray1(camera{pr}.camera_model.prnu);
            prnu = WienerInDFT(prnu,std2(prnu));
            prnu = prnu .* image2;
            list_corr(pr) = corr2(prnu, noise);
        end
        [max_corr, max_ind] = max(list_corr(:));

        %fix some parameter
        w = [30, 2.5];
        threshold = 0.5;

        if max_corr > 0.01
            %here is the possibility of doing the fuseCRF but is better don't
            %do it and go directly with segmentwise_correlation
            remake = false;
            
            windows = [97 129 193 257];
            resp = cell(1, numel(windows));

            for win = 1 : numel(windows)
                %calculate all the map needed for the fusion part
                result_itermediate  = detectForgeryPRNUCentral(image, camera{max_ind}.camera_model, windows(win), ...
                    struct('verbose', true, 'stride', 8, 'image_padding', true));
                resp{win}.candidate = result_itermediate.map_prp;
                %onece you get the map you calculate the reliability
                resp{win}.reliability = 1 - exp(-abs(w(1)*(resp{win}.candidate - 0.5).^w(2)));
            end

            try
                %valori aggiustati della fuse
                fusion_labeling = fuseCRF(resp, image, 0.4, [-1 0.7 6.6 25 0.18]);
                %fusion_labeling = fuseCRF(resp, image, threshold, [-1 0.5 5.6 25 0.18]);
                
                
                somma_PRNU = sum(fusion_labeling(:) == 1);
                
                if somma_PRNU < 1000 || somma_PRNU > 44000
                    fprintf(debug, 'FAIL: PRNUloc with fuseCRF, min tresh not get \n');
                    fprintf(debug, 'FAIL: we pass to Central detection with segmentwise_correletion \n');
                    fprintf(debug, 'FAIL: we pass to gabor computation \n');
                    remake = ture;
                    make_other = true;
                else
                    fusion_labeling = mapCleanup(fusion_labeling, 64);
                    %fusion_labeling = imfill(fusion_labeling, 'holes');
                    fusion_labeling = imresize(fusion_labeling, [1500 2000]);
                    imwrite(fusion_labeling, result_name, 'bmp');
                    name_out = result_name;
                    fprintf(debug, ['Image ' main_name ' computed with PRNUloc with fuseCRF \n']);
                end
                
            catch
                fprintf(debug, 'FATAL: error when using fuseCRF algorithm  \n');
                fprintf(debug, 'FATAL: we pass to Central detection with segmentwise_correletion \n');
                fprintf(debug, 'FAIL: we pass to gabor computation \n');
                remake = true;
                make_other = true;
            end
            

            %{
            if remake
                ottimal_result = detectForgeryPRNUCentral(image, camera{max_ind}.camera_model, 129, ...
                    struct('verbose', true, 'stride', 8, 'segmentwise_correlation', true, 'image_padding', true));


                imm = ottimal_result.map_prp > threshold;
                somma_PRNU = sum(imm(:) == 1);
                
                if somma_PRNU < 1000 || somma_PRNU > 44000
                    fprintf(debug, 'FAIL: PRNUloc with segmentwise_correletion, min tresh not get \n');
                    fprintf(debug, 'FAIL: we pass to ERROR IMAGE');
                else
                    imm = mapCleanup(imm, 64);
                    %imm = imfill(imm, 'holes');
                    imm = imresize(imm, [1500 2000]);
                    imwrite(imm, result_name, 'bmp');
                    name_out = result_name;
                    fprintf(debug, ['Image ' main_name ' computed with PRNUloc \n']);
                end
            end
            %}

        else
            % if the program go here we are in trouble
            fprintf(debug, 'FAIL: PRNU correletion fail to the min tresh \n');
            fprintf(debug, 'FAIL: we pass to gabor computation \n');
            make_other = true;
        end
    catch
        fprintf(debug, 'FATAL: Attemp to make PRNU localizazion, fatal exception occour, may be the function mdwt that was not compiled \n');
        fprintf(debug, 'FATAL: we pass to gabor computation \n');
        make_other = true;
    end
end

%%
%here is the session of doing other things
if make_other
    
    
    try
        map = gabor_b(image);
        map = imresize(map, [1500 2000]);
        imwrite(map, result_name, 'bmp');
        name_out = result_name;
        fprintf(debug, ['Image ' main_name ' computed with gabor\n']);
        
    catch
        
        C = [1, 1, 1, 1; 1, 0, 0, 1; 1, 0, 0, 1; 1, 1, 1, 1;];
        C = (C == 0);
        C = imresize(C, [1500 2000]);

        imwrite(C, result_name, 'bmp');
        name_out = result_name;

        fprintf(debug, ['FATAL: Image ' main_name ' was not able to be computed \n']);
        fprintf(debug, 'FATAL: A standard image was given in output \n');
        
    end
end

fprintf(debug, ['END: at' datestr(datetime('now')) '\n']);

end

