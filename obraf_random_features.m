clear
clc

method = 'obRaF-random';

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
    validation_train = logical(validation_train);
    validation_test = logical(validation_test);
    
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
    
    [Nsample,nfea]=size(dataX);
    if Nsample<10000
        NN=[256,512,1024];
    else
        NN=[1024,2048,4096];
    end
	
	%%Extended Random Features%%
	
	option_save1=[];
    % crossvalidation
    for num_CV=1:numOffold

        test_index = folds(:,num_CV);
        train_index = logical(1-test_index);

        validation_train_index = validation_train(:,(num_CV-1)*4+1:num_CV*4);
        validation_test_index = validation_test(:,(num_CV-1)*4+1:num_CV*4);
        
        MAX_ACC = 0;
        
        for nt=1:length(NN)
            for n_activation=1:9
                option_temp.ntrees=500;
                option_temp.N=NN(nt);
                option_temp.activation=n_activation;
                
                ACC_TMP=zeros(1,4);
                for i=1:4
                        
                        trainX_val = dataX(validation_train_index(:,i),:);
                        trainY_val = dataY(validation_train_index(:,i),:);
                        testX_val = dataX(validation_test_index(:,i),:);
                        testY_val = dataY(validation_test_index(:,i),:);
                        [trainX_val,testX_val] = Extend_Random_features(trainX_val,testX_val,option_temp);
                        option_temp.nvartosample=round(sqrt(size(trainX_val,2)));
                        
                        [ACC_TMP(1,i),~]  = Oblique_RF(trainX_val,trainY_val,testX_val,testY_val,option_temp);
                end
                if mean(ACC_TMP)>MAX_ACC
                    option=option_temp;
                    MAX_ACC=mean(ACC_TMP);
                end
            end
        end
        
        trainX = dataX(train_index,:);
        trainY = dataY(train_index,:);
        testX = dataX(test_index,:);
        testY = dataY(test_index,:);

        [trainX,testX] = Extend_Random_features(trainX,testX,option);
        option.nvartosample=round(sqrt(size(trainX,2)));

        [ACC(1,num_CV),Model_tree{1,num_CV}]  = Oblique_RF(trainX,trainY,testX,testY,option);
		option_save1=[option_save1, option];
    end
	mean(ACC)
	results.Enhanced_Mean_Acc = ACC;
	
    results.option1=option_save1;
	
	
    %% Save Results to File
    filename = [path1 'Res_' dataset_name '.mat'];
    save (filename, 'results');

	file_XLS=[path1 'fixed_all_results.xlsx']
	C = {dataset_name, round(100*mean(results.Enhanced_Mean_Acc),2)};
	writecell(C, file_XLS, "WriteMode", "append");
end

function [names,class_num] = GetFiles(dataset_path)
files = dir(dataset_path);
size0 = size(files);
length = size0(1);
names = files(3:length);
class_num = size(names);
end