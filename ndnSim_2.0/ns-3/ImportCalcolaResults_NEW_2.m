%SIM = input ('Input the sim name: ');
%T = input ('Input the sim type: ');
%M = input ('Input the catalog cardinality: ');
%C = input ('Input the cache to catalog ratio: ');
%L = input ('Input the lambda: ');
%A = input ('Input the Zipf Exponent: ');
%R = input ('Input the number of runs: ');

% STRINGHE 

stringOutput = 'DATA_SIM=ICARUS_T=SINGLE_CACHE_A=12_REQ=100000000.mat';

simulatorStr = cell(1,4);
simulatorStr{1} = 'CCNSIM';
simulatorStr{2} = 'NDNSIM';
simulatorStr{3} = 'ICARUS';
simulatorStr{4} = 'CCNPL';

scenarioStr = cell(1,1);
scenarioStr{1} = 'SINGLE_CACHE';

catalogStr = cell(1,1);
catalogStr{1} = '10000';

ratioStr = cell(1,1);
ratioStr{1} = '0.01';

lambdaStr = cell(1,1);
lambdaStr{1} = '4';

alphaStr = cell(1,4);
alphaStr{1} = '0.6';
alphaStr{2} = '0.8';
alphaStr{3} = '1';
alphaStr{4} = '1.2';

alphaStrCompl = cell(1,4);
alphaStrCompl{1} = 'alpha_06';
alphaStrCompl{2} = 'alpha_08';
alphaStrCompl{3} = 'alpha_1';
alphaStrCompl{4} = 'alpha_12';

alphaValues = [0.6 0.8 1 1.2];

simRuns = 10;
numRequests = 100100000;
officialNumRequests = 100000000;
reqStr = '100000000';
catalog = 10000;
IDs = 1:catalog;
target = 100;

tStudent = [1.2 6.314 2.920 2.353 2.132 2.015 1.943 1.895 1.860 1.833 1.812 1.796];

% Valori effettivi dei parametri simulati (servono a prendere le stringhe

numSimulators = [3];
numScenarios = [1];
numCatalogs = [1];
numRatios = [1];
numLambdas = [1];
%numAlphas = [1 2 3 4];
numAlphas = [4];


% Import Che Approx
fileChePrefix = '/home/tortelli/ndn-simulator-comparison/Results/HitCheTeo_';
fileCheSuffix = '.txt';
Che_Approx = struct;

for g=1:length(numAlphas)
    fileCheCompl = strcat(fileChePrefix, alphaStr{numAlphas(g)}, fileCheSuffix); 
    fileID = fopen(fileCheCompl);
    fileCheCompl
    Che_Approx.(alphaStrCompl{numAlphas(g)}) = textscan(fileID,'%f32');
    fileID = fclose(fileID);
end


% Dichiarazione STRUCT per import

scenarioImport = struct;
contentID = struct;
hitDistance = struct;
limitRequests = struct;

% Inizializzazione Matrici per ContentID e HitDistance
for g = 1:length(numAlphas)
    for j = 1:length(numSimulators)
        contentID.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(numRequests, simRuns);
        hitDistance.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(numRequests, simRuns);
        limitRequests.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(simRuns,1);
    end
end


folder='/home/tortelli/ndn-simulator-comparison/Results/logs/';
ext='.out';

minLimit = struct;

for g=1:length(numAlphas)
    minLimit.(alphaStrCompl{numAlphas(g)}) = officialNumRequests;
end

for g = 1:length(numAlphas)
    for j = 1:length(numSimulators)
        for i=0:simRuns-1
            run = int2str(i);
            disp(sprintf('%s',strcat(simulatorStr{numSimulators(j)}, ' ' ,run)));
            nome_file=strcat(folder,'SIM=',simulatorStr{numSimulators(j)},'_T=',scenarioStr{numScenarios(1)},'_REQ=',reqStr,'_M=',catalogStr{numCatalogs(1)},'_C=',ratioStr{numRatios(1)},'_L=',lambdaStr{numLambdas(1)},'_A=',alphaStr{numAlphas(g)},'_R=',run,ext);
            %nome_file=strcat(folder,'SIM=',simulatorStr{numSimulators(j)},'_T=',scenarioStr{numScenarios(1)},'_M=',catalogStr{numCatalogs(1)},'_C=',ratioStr{numRatios(1)},'_L=',lambdaStr{numLambdas(1)},'_A=',alphaStr{numAlphas(g)},'_R=',run,ext);
            %nome_file
	    disp(sprintf('%s', nome_file));
	    fileID = fopen(nome_file);
            scenarioImport.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = textscan(fileID,'%d32 %d8');
            fileID = fclose(fileID);
            limit = length(scenarioImport.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}){1});
            limitRequests.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i+1,1) = limit;
            if (limitRequests.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i+1,1) < minLimit.(alphaStrCompl{numAlphas(g)}))
                minLimit.(alphaStrCompl{numAlphas(g)}) = limitRequests.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i+1,1);
            end
            contentID.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(1:limit,i+1) = scenarioImport.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}){1}(1:limit,1);
            hitDistance.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(1:limit,i+1) = scenarioImport.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}){2}(1:limit,1);
            clear scenarioImport;
        end
    end
end

clear scenarioImport;
clear limitRequests;

% minLimit = struct;
% 
% for g=1:length(numAlphas)
%     minLimit.(alphaStrCompl{numAlphas(g)}) = officialNumRequests;
% end

% Search the minimum number of requests between the simulated scenarios, and reduce the dimension of the matrices accordingly 

% for g=1:length(numAlphas)
%     for j = 1:length(numSimulators)
%         for i=0:simRuns-1
%             if (limitRequests.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i+1,1) < minLimit.(alphaStrCompl{numAlphas(g)}))
%                 minLimit.(alphaStrCompl{numAlphas(g)}) = limitRequests.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i+1,1);
%             end
%         end
%     end
% end


for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        contentID.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(minLimit.(alphaStrCompl{numAlphas(g)})+1:numRequests,:) = [];
        hitDistance.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(minLimit.(alphaStrCompl{numAlphas(g)})+1:numRequests,:) = [];
    end
end

% Calculate the Theoretical number of request per each content
%alphaValue = 1;

zipfLimit = struct;
zipf = struct;
normFactor = struct;
freqZipf = struct;

for g=1:length(numAlphas)
    normFactor.(alphaStrCompl{numAlphas(g)}) = 0;
    zipf.(alphaStrCompl{numAlphas(g)}) = zeros(1, catalog);
end

for g=1:length(numAlphas)
    for z=1:catalog
        normFactor.(alphaStrCompl{numAlphas(g)}) = normFactor.(alphaStrCompl{numAlphas(g)}) + (1/z^alphaValues((numAlphas(g))));
    end
end

for g=1:length(numAlphas)
    normFactor.(alphaStrCompl{numAlphas(g)}) = 1 / normFactor.(alphaStrCompl{numAlphas(g)});
end

for g=1:length(numAlphas)
    for z=1:catalog
        zipf.(alphaStrCompl{numAlphas(g)})(1,z) = normFactor.(alphaStrCompl{numAlphas(g)}) * (1/z^alphaValues((numAlphas(g))));
        freqZipf.(alphaStrCompl{numAlphas(g)}) = minLimit.(alphaStrCompl{numAlphas(g)}) * zipf.(alphaStrCompl{numAlphas(g)});
    end
end


%zipf = alphaValue./(1:catalog);
%zipf = zipf/sum(zipf);
%freqZipf = minLimit * zipf;

% Find the Content ID that correspond to the X-th percentile
czipf = struct;
cont50 = struct;
cont75 = struct;
cont90 = struct;
cont95 = struct;

for g = 1:length(numAlphas)
    czipf.(alphaStrCompl{numAlphas(g)}) = cumsum(zipf.(alphaStrCompl{numAlphas(g)}));
    cont50.(alphaStrCompl{numAlphas(g)}) = find(czipf.(alphaStrCompl{numAlphas(g)})>=.50,1);
    cont75.(alphaStrCompl{numAlphas(g)}) = find(czipf.(alphaStrCompl{numAlphas(g)})>=.75,1);
    cont90.(alphaStrCompl{numAlphas(g)}) = find(czipf.(alphaStrCompl{numAlphas(g)})>=.90,1);
    cont95.(alphaStrCompl{numAlphas(g)}) = find(czipf.(alphaStrCompl{numAlphas(g)})>=.95,1);
end

%czipf = cumsum(zipf);
%cont50 = find(czipf>=.50,1);
%cont75 = find(czipf>=.75,1);
%cont90 = find(czipf>=.90,1);
%cont95 = find(czipf>=.95,1);


% Struct to accomodate the total probability of hit ratio and the Phit for
% each content

pHitTotalRuns = struct;
pHitContentsRuns = struct; 
pMissContentsRuns = struct;
%pHitContentsNEW = struct;
%cdfHitContentsNEW = struct;

frequencyHitContents = struct;
frequencyMissContents = struct;
frequencyRequestsContents = struct;
%frequencyRequestsContentsBIN = struct;
%xAxesBIN = struct;

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        pHitTotalRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(simRuns,1);
        pHitContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, simRuns);
        pMissContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, simRuns);
        %pHitContentsNEW.(simulatorStr{numSimulators(j)}) = zeros(catalog, simRuns);
        %cdfHitContentsNEW.(simulatorStr{numSimulators(j)}) = zeros(catalog, simRuns);
        frequencyHitContents.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, 1);
        frequencyMissContents.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, 1);
        frequencyRequestsContents.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, 1);
    end
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for i = 0:simRuns-1
            for z = 1:minLimit.(alphaStrCompl{numAlphas(g)})
                if (hitDistance.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,i+1) == 0)    % It means a Cache Hit
                    pHitTotalRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i+1,1) = pHitTotalRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i+1,1) + 1;
                    w = contentID.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,i+1);  % Keep the correspondent content ID
                    pHitContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(w,i+1) = pHitContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(w,i+1) + 1;
                else
                    m = contentID.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,i+1);  % Keep the correspondent content ID
                    pMissContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(m,i+1) = pMissContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(m,i+1) + 1;
                end
            end
        end
    end
end

clear contentID;
clear hitDistance;

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for z = 1:catalog
            frequencyHitContents.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1) = mean(pHitContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,:));
            frequencyMissContents.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1) = mean(pMissContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,:));
            frequencyRequestsContents.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1) = frequencyHitContents.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1) + frequencyMissContents.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1);
        end
    end
end

%%%%%%%%%%%%%%%%     BINNING  %%%%%%%%%%%%%%%%%%%%%%%%%%

% for g=1:length(numAlphas)
%     for j = 1:length(numSimulators)
%         [xAxesBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}), frequencyRequestsContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})] = variableBINS(IDs, frequencyRequestsContents.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}), target);
%         [xAxesZipfBIN.(alphaStrCompl{numAlphas(g)}), frequencyRequestsZipfBIN.(alphaStrCompl{numAlphas(g)})] = variableBINS(IDs, freqZipf.(alphaStrCompl{numAlphas(g)})', target);
%     end
% end
% 
% minBinMax = struct;
% for g=1:length(numAlphas)
%     minBinMax.(alphaStrCompl{numAlphas(g)}) = catalog;
% end
% 
% for g=1:length(numAlphas)
%     for j = 1:length(numSimulators)
%         if length(frequencyRequestsContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(:,1)) < minBinMax.(alphaStrCompl{numAlphas(g)})
%             minBinMax.(alphaStrCompl{numAlphas(g)}) = length(frequencyRequestsContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(:,1));
%         end
%     end
% end
% for g=1:length(numAlphas)
%     if length(frequencyRequestsZipfBIN.(alphaStrCompl{numAlphas(g)})(:,1)) < minBinMax.(alphaStrCompl{numAlphas(g)})
%         minBinMax.(alphaStrCompl{numAlphas(g)}) = length(frequencyRequestsZipfBIN.(alphaStrCompl{numAlphas(g)})(:,1));
%     end
% end
% 
% for g=1:length(numAlphas)
%     for j = 1:length(numSimulators)
%         frequencyRequestsContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = frequencyRequestsContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(1:minBinMax.(alphaStrCompl{numAlphas(g)}),1);
%         xAxesBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = xAxesBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(1:minBinMax.(alphaStrCompl{numAlphas(g)}),1);
%     end
% end
% 
% for g=1:length(numAlphas)
%     frequencyRequestsZipfBIN.(alphaStrCompl{numAlphas(g)}) = frequencyRequestsZipfBIN.(alphaStrCompl{numAlphas(g)})(1:minBinMax.(alphaStrCompl{numAlphas(g)}),1);
%     xAxesZipfBIN.(alphaStrCompl{numAlphas(g)}) = xAxesZipfBIN.(alphaStrCompl{numAlphas(g)})(1:minBinMax.(alphaStrCompl{numAlphas(g)}),1);
% end
% 
% frequencyHitContentsBIN = struct;
% pHitContentsBIN = struct;
% 
% for g=1:length(numAlphas)
%     for j = 1:length(numSimulators)
%         frequencyHitContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(minBinMax.(alphaStrCompl{numAlphas(g)}),1);
%         pHitContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(minBinMax.(alphaStrCompl{numAlphas(g)}),1);
%     end
% end
% 
% % Average the Hit Events according to the BIN calculated before, and
% % calculating the Hit Probability accordingly.
% 
% %start = 1;
% for g=1:length(numAlphas)
%     for j = 1:length(numSimulators)
%         start = 1;
%         for i = 1:minBinMax.(alphaStrCompl{numAlphas(g)})
%             p = xAxesBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i,1);
%             frequencyHitContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i,1) = mean(frequencyHitContents.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(start:p,1));
%             pHitContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i,1) = frequencyHitContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i,1) / frequencyRequestsContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i,1);
%             start = p+1;
%         end
%     end
% end
% 
% pHitCheBIN = struct;
% 
% for g=1:length(numAlphas)
%     pHitCheBIN.(alphaStrCompl{numAlphas(g)}) = zeros(minBinMax.(alphaStrCompl{numAlphas(g)}),1);
% end
% 
% %start = 1;
% for g=1:length(numAlphas)
%     start = 1;
%     for i = 1:minBinMax.(alphaStrCompl{numAlphas(g)})
%         p = xAxesZipfBIN.(alphaStrCompl{numAlphas(g)})(i,1);
%         pHitCheBIN.(alphaStrCompl{numAlphas(g)})(i,1) = mean(Che_Approx.(alphaStrCompl{numAlphas(g)}){1}(start:p,1));
%         start = p+1;
%     end
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for i = 0:simRuns-1
            for z = 1:catalog
                pHitContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,i+1) = pHitContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,i+1) /(pHitContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,i+1) + pMissContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,i+1));
            end
        end
    end
end

% for j = 1:length(numSimulators)
%     for i = 0:simRuns-1
%         for z = 1:catalog
%             pHitContentsRuns.(simulatorStr{numSimulators(j)})(z,i+1) = pHitContentsRuns.(simulatorStr{numSimulators(j)})(z,i+1) /(pHitContentsRuns.(simulatorStr{numSimulators(j)})(z,i+1) + pMissContentsRuns.(simulatorStr{numSimulators(j)})(z,i+1));
%             if z==1
%                 cdfHitContentsNEW.(simulatorStr{numSimulators(j)})(z,i+1) =  pHitContentsRuns.(simulatorStr{numSimulators(j)})(z,i+1);
%             else
%                 cdfHitContentsNEW.(simulatorStr{numSimulators(j)})(z,i+1) =  pHitContentsRuns.(simulatorStr{numSimulators(j)})(z,i+1) - pHitContentsRuns.(simulatorStr{numSimulators(j)})(z-1,i+1);
%             end
%             pHitContentsNEW.(simulatorStr{numSimulators(j)})(z,i+1) = 1 - cdfHitContentsNEW.(simulatorStr{numSimulators(j)})(z,i+1);
%         end
%     end
% end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for i = 0:simRuns-1
            pHitTotalRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i+1,1) = pHitTotalRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(i+1,1) / minLimit.(alphaStrCompl{numAlphas(g)});
        end
    end
end

pHitTotalMean = struct;
pHitContentsMean = struct;

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        pHitTotalMean.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = mean(pHitTotalRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(:,1));
    end
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        pHitContentsMean.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}).('mean') = zeros(catalog, 1);
        pHitContentsMean.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}).('std') = zeros(catalog, 1);
        pHitContentsMean.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}).('conf') = zeros(catalog, 1);
    end
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for z = 1:catalog
            pHitContentsMean.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}).('mean')(z,1) = mean(pHitContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,:));
            pHitContentsMean.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}).('std')(z,1) = std(pHitContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,:));
            pHitContentsMean.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}).('conf')(z,1) = tStudent(1, simRuns-1) * ( pHitContentsMean.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}).('std')(z,1) / sqrt(simRuns));
        end
    end
end

%clear scenarioImport;
clear pHitContentsRuns;

%clear contentID;
%clear hitDistance;

% Plot Phit per each content
pHit = struct;
for g=1:length(numAlphas)
    pHit.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 2);
end
for g=1:length(numAlphas)
    pHit.(alphaStrCompl{numAlphas(g)})(:,1) = pHitContentsMean.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(1)}).('mean')(:,1);
    %pHit.(alphaStrCompl{numAlphas(g)})(:,2) = pHitContentsMean.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(2)}).('mean')(:,1);    
    %pHit.(alphaStrCompl{numAlphas(g)})(:,3) = pHitContentsMean.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(3)}).('mean')(:,1);
    pHit.(alphaStrCompl{numAlphas(g)})(:,2) = Che_Approx.(alphaStrCompl{numAlphas(g)}){1}(:,1);
    %createHitLogPlot(IDs, pHit.(alphaStrCompl{numAlphas(g)}), 1, numAlphas(g));
end

% Build pHit normalized to Che_Approx
norm = struct;
pHitNormalized = struct;
for g=1:length(numAlphas)
    %norm.(alphaStrCompl{numAlphas(g)}) = [pHit.(alphaStrCompl{numAlphas(g)})(:,4), pHit.(alphaStrCompl{numAlphas(g)})(:,4), pHit.(alphaStrCompl{numAlphas(g)})(:,4), pHit.(alphaStrCompl{numAlphas(g)})(:,4)];
    norm.(alphaStrCompl{numAlphas(g)}) = [pHit.(alphaStrCompl{numAlphas(g)})(:,2), pHit.(alphaStrCompl{numAlphas(g)})(:,2)];
    pHitNormalized.(alphaStrCompl{numAlphas(g)}) = zeros(catalog,2);
end
for g=1:length(numAlphas)
    pHitNormalized.(alphaStrCompl{numAlphas(g)}) = pHit.(alphaStrCompl{numAlphas(g)})./norm.(alphaStrCompl{numAlphas(g)});
    %createHitLogPlot(IDs, pHitNormalized.(alphaStrCompl{numAlphas(g)}), 2, numAlphas(g));
end

% Plot Phit per each content
% IDsBIN = struct;
% pHitBinning = struct;
% for g=1:length(numAlphas)
%     IDsBIN.(alphaStrCompl{numAlphas(g)}) = 1:minBinMax.(alphaStrCompl{numAlphas(g)});
%     pHitBINNING.(alphaStrCompl{numAlphas(g)}) = zeros(minBinMax.(alphaStrCompl{numAlphas(g)}), 4);
% end
% for g=1:length(numAlphas)
%     pHitBINNING.(alphaStrCompl{numAlphas(g)})(:,1) = pHitContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(1)})(:,1);
%     pHitBINNING.(alphaStrCompl{numAlphas(g)})(:,2) = pHitContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(2)})(:,1);
%     pHitBINNING.(alphaStrCompl{numAlphas(g)})(:,3) = pHitContentsBIN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(3)})(:,1);
%     pHitBINNING.(alphaStrCompl{numAlphas(g)})(:,4) = pHitCheBIN.(alphaStrCompl{numAlphas(g)})(:,1);
%     createHitLogPlot(IDsBIN.(alphaStrCompl{numAlphas(g)}), pHitBINNING.(alphaStrCompl{numAlphas(g)}), 3, numAlphas(g));
% end

% Build pHit BIN normalized to Che_Approx
% normBIN = struct;
% pHitNormalizedBINNING = struct;
% for g=1:length(numAlphas)
%     normBIN.(alphaStrCompl{numAlphas(g)}) = [pHitBINNING.(alphaStrCompl{numAlphas(g)})(:,4), pHitBINNING.(alphaStrCompl{numAlphas(g)})(:,4), pHitBINNING.(alphaStrCompl{numAlphas(g)})(:,4), pHitBINNING.(alphaStrCompl{numAlphas(g)})(:,4)];
%     pHitNormalizedBINNING.(alphaStrCompl{numAlphas(g)}) = zeros(catalog,4);
% end
% for g=1:length(numAlphas)
%     pHitNormalizedBINNING.(alphaStrCompl{numAlphas(g)}) = pHitBINNING.(alphaStrCompl{numAlphas(g)})./normBIN.(alphaStrCompl{numAlphas(g)});
%     createHitLogPlot(IDsBIN.(alphaStrCompl{numAlphas(g)}), pHitNormalizedBINNING.(alphaStrCompl{numAlphas(g)}), 4, numAlphas(g));
% end


% Calculating the function f(x,che) = (che - x)/che, both for pHit and for
% pHitNormalized
fForPhit = struct;
fForPhitNormalized = struct;
for g=1:length(numAlphas)
    %fForPhit.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
    %fForPhitNormalized.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
    fForPhit.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
    fForPhitNormalized.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for z = 1:catalog
            fForPhit.(alphaStrCompl{numAlphas(g)})(z,j) = (pHit.(alphaStrCompl{numAlphas(g)})(z,2) - pHit.(alphaStrCompl{numAlphas(g)})(z,j)) / pHit.(alphaStrCompl{numAlphas(g)})(z,2);
            fForPhitNormalized.(alphaStrCompl{numAlphas(g)})(z,j) = (pHitNormalized.(alphaStrCompl{numAlphas(g)})(z,2) - pHitNormalized.(alphaStrCompl{numAlphas(g)})(z,j)) / pHitNormalized.(alphaStrCompl{numAlphas(g)})(z,2);
        end
    end
end


%% NEW ERROR PLOT

errNorm = struct;
denSum = struct;

for g=1:length(numAlphas)
    errNorm.(alphaStrCompl{numAlphas(g)}) = zeros(1, catalog);
    denSum.(alphaStrCompl{numAlphas(g)}) = sum(zipf.(alphaStrCompl{numAlphas(g)}));
end

for g=1:length(numAlphas)
    for z = 1:catalog
        errNorm.(alphaStrCompl{numAlphas(g)})(1,z) = zipf.(alphaStrCompl{numAlphas(g)})(1,z)/denSum.(alphaStrCompl{numAlphas(g)});
        %errNorm.(alphaStrCompl{numAlphas(g)})(1,z) = zipf.(alphaStrCompl{numAlphas(g)})(1,z);
    end
end

fForPhitWeighted = struct;
fForPhitNormalizedWeighted = struct;
for g=1:length(numAlphas)
    %fForPhitWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
    %fForPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
    fForPhitWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
    fForPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
end


for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for z = 1:catalog
            fForPhitWeighted.(alphaStrCompl{numAlphas(g)})(z,j) = fForPhit.(alphaStrCompl{numAlphas(g)})(z,j) * errNorm.(alphaStrCompl{numAlphas(g)})(1,z);
            fForPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)})(z,j) = fForPhitNormalized.(alphaStrCompl{numAlphas(g)})(z,j) * errNorm.(alphaStrCompl{numAlphas(g)})(1,z);
        end
    end
end

% Expected F for Phit Weighted  E[ei*pi]

expectFforPhitWeighted = struct;
expectFforPhitNormalizedWeighted = struct;
for g=1:length(numAlphas)
    %expectFforPhitWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
    %expectFforPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
    expectFforPhitWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
    expectFforPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for z = 1:catalog
            if z < catalog
                expectFforPhitWeighted.(alphaStrCompl{numAlphas(g)})(z,j) = mean(fForPhitWeighted.(alphaStrCompl{numAlphas(g)})(z+1:catalog,j));
                expectFforPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)})(z,j) = mean(fForPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)})(z+1:catalog,j));
            else
                expectFforPhitWeighted.(alphaStrCompl{numAlphas(g)})(z,j) = fForPhitWeighted.(alphaStrCompl{numAlphas(g)})(z,j);
                expectFforPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)})(z,j) = fForPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)})(z,j);
            end
        end
    end
end



% Expected F for ABS Phit Weighted  E[||ei*pi||]

expectAbsFforPhitWeighted = struct;
expectAbsFforPhitNormalizedWeighted = struct;
for g=1:length(numAlphas)
    %expectAbsFforPhitWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
    %expectAbsFforPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
    expectAbsFforPhitWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
    expectAbsFforPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for z = 1:catalog
            if z < catalog
                expectAbsFforPhitWeighted.(alphaStrCompl{numAlphas(g)})(z,j) = mean(abs(fForPhitWeighted.(alphaStrCompl{numAlphas(g)})(z+1:catalog,j)));
                expectAbsFforPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)})(z,j) = mean(abs(fForPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)})(z+1:catalog,j)));
            else
                expectAbsFforPhitWeighted.(alphaStrCompl{numAlphas(g)})(z,j) = abs(fForPhitWeighted.(alphaStrCompl{numAlphas(g)})(z,j));
                expectAbsFforPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)})(z,j) = abs(fForPhitNormalizedWeighted.(alphaStrCompl{numAlphas(g)})(z,j));
            end
        end
    end
end


% Expected F for Phit E[ei]

expectFforPhit = struct;
expectFforPhitNormalized = struct;
for g=1:length(numAlphas)
   % expectFforPhit.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
   % expectFforPhitNormalized.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
    expectFforPhit.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
    expectFforPhitNormalized.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for z = 1:catalog
            if z < catalog
                expectFforPhit.(alphaStrCompl{numAlphas(g)})(z,j) = mean(fForPhit.(alphaStrCompl{numAlphas(g)})(z+1:catalog,j));
                expectFforPhitNormalized.(alphaStrCompl{numAlphas(g)})(z,j) = mean(fForPhitNormalized.(alphaStrCompl{numAlphas(g)})(z+1:catalog,j));
            else
                expectFforPhit.(alphaStrCompl{numAlphas(g)})(z,j) = fForPhit.(alphaStrCompl{numAlphas(g)})(z,j);
                expectFforPhitNormalized.(alphaStrCompl{numAlphas(g)})(z,j) = fForPhitNormalized.(alphaStrCompl{numAlphas(g)})(z,j);
            end
        end
    end
end


% Expected F for ABS Phit E[|ei|]

expectAbsFforPhit = struct;
expectAbsFforPhitNormalized = struct;
for g=1:length(numAlphas)
    %expectAbsFforPhit.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
    %expectAbsFforPhitNormalized.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 3);
    expectAbsFforPhit.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
    expectAbsFforPhitNormalized.(alphaStrCompl{numAlphas(g)}) = zeros(catalog, 1);
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for z = 1:catalog
            if z < catalog
                expectAbsFforPhit.(alphaStrCompl{numAlphas(g)})(z,j) = mean(abs(fForPhit.(alphaStrCompl{numAlphas(g)})(z+1:catalog,j)));
                expectAbsFforPhitNormalized.(alphaStrCompl{numAlphas(g)})(z,j) = mean(abs(fForPhitNormalized.(alphaStrCompl{numAlphas(g)})(z+1:catalog,j)));
            else
                expectAbsFforPhit.(alphaStrCompl{numAlphas(g)})(z,j) = abs(fForPhit.(alphaStrCompl{numAlphas(g)})(z,j));
                expectAbsFforPhitNormalized.(alphaStrCompl{numAlphas(g)})(z,j) = abs(fForPhitNormalized.(alphaStrCompl{numAlphas(g)})(z,j));
            end
        end
    end
end



% Calculating the function f() for significative contents, i.e., p50, p75,
% p90, p95

f50_REQ_100mln = struct;
for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        f50_REQ_100mln.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = expectAbsFforPhit.(alphaStrCompl{numAlphas(g)})(cont50.(alphaStrCompl{numAlphas(g)}),j);
    end
end

f75_REQ_100mln = struct;
for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        f75_REQ_100mln.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = expectAbsFforPhit.(alphaStrCompl{numAlphas(g)})(cont75.(alphaStrCompl{numAlphas(g)}),j);
    end
end

f90_REQ_100mln = struct;
for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        f90_REQ_100mln.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = expectAbsFforPhit.(alphaStrCompl{numAlphas(g)})(cont90.(alphaStrCompl{numAlphas(g)}),j);
    end
end

f95_REQ_100mln = struct;
for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        f95_REQ_100mln.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = expectAbsFforPhit.(alphaStrCompl{numAlphas(g)})(cont95.(alphaStrCompl{numAlphas(g)}),j);
    end
end
save(stringOutput);
