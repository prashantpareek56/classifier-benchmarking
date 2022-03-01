clear
clc

method = 'obRaF';

dataset_path = 'D:\project-btp\Shared_Datasets\'; % Need to change
path1 = ['D:\project-btp\results\rvfl\results-date\' method '\']

if ~exist(path1)
    mkdir(path1)
end

[name,num] = GetFiles(dataset_path);
n_folders = num(1);


for dataset_num = 1:n_folders
    dataset_name = name(dataset_num).name;
    dataset_name
    
    if dataset_num ~= 4
        continue
    end
    %% Skip the Dataset if it exists
    filename = [path1 'Res_' dataset_name '.mat'];
    if  exist(filename) % SKip the completed datasets
        continue
    end
    
    dataset_path_name = strcat(dataset_path,dataset_name,'\');
    load([dataset_path_name 'folds.mat']);
    load(strcat(dataset_path_name,dataset_name, '.mat'))
    load([dataset_path_name 'labels.mat']);
    load([dataset_path_name 'validation_train.mat']);
    load([dataset_path_name 'validation_test.mat']);
    try
        load([dataset_path_name 'numOffold.mat']);
    catch
        numOffold = size(folds,2); %4-fold CV
    end
    numOffold = numOffold; %4-fold CV
    expression = strcat('dataX = ',dataset_name,';');
    
    eval(expression);
    dataY=labels;
    folds = logical(folds);
    
    U_dataY = unique(dataY);
    nclass = numel(U_dataY);
    dataY_temp = zeros(numel(dataY),nclass);
    
    % 0-1 coding for the target
    for i=1:nclass
        idx = dataY==U_dataY(i);
        dataY_temp(idx,i)=1;
    end
    
    option.nvartosample = round(sqrt(size(dataX,2))); %default;
    option.ntrees = 500;
    
    ACC = zeros(1,numOffold);
    Model_tree = cell(1,numOffold);
    
    % crossvalidation
    for num_CV=1:numOffold
        
        test_index = folds(:,num_CV);
        train_index = logical(1-test_index);
        
        trainX = dataX(train_index,:);
        trainY = dataY(train_index,:);
        testX = dataX(test_index,:);
        testY = dataY(test_index,:);
        
        [ACC(1,num_CV),Model_tree{1,num_CV}]  = Oblique_RF(trainX,trainY,testX,testY,option);
    end
    mean(ACC)
    %% save
    results.ACC = ACC;
    
    %% Save Results to File
    filename = [path1 'Res_' dataset_name '.mat'];
    save (filename, 'results');
    
    if mean(results.ACC) ~= 0
        xlRange1 = ['A' num2str(dataset_num)];
        xlswrite([path1 'fixed_all_results.xlsx'], {dataset_name}, 1, xlRange1);
        xlRange2 = ['B' num2str(dataset_num)];
        xlswrite([path1 'fixed_all_results.xlsx'], round(100*mean(results.ACC),2), 1, xlRange2);
    end
end

function [names,class_num] = GetFiles(dataset_path)
files = dir(dataset_path);
size0 = size(files);
length = size0(1);
names = files(3:length);
class_num = size(names);
end