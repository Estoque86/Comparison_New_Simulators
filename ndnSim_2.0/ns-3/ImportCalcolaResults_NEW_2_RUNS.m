%SIM = input ('Input the sim name: ');
%T = input ('Input the sim type: ');
%M = input ('Input the catalog cardinality: ');
%C = input ('Input the cache to catalog ratio: ');
%L = input ('Input the lambda: ');
%A = input ('Input the Zipf Exponent: ');
%R = input ('Input the number of runs: ');

% STRING 

stringOutput = 'DATA_SIM=ndnSIM_Icarus_T=SINGLE_CACHE_M=1e4_R=1e6.mat';

simulatorStr = cell(1,4);
simulatorStr{1} = 'CCNSIM';
simulatorStr{2} = 'ndnSIM';
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

simRuns = 2;
numRequests = 1001000;
officialNumRequests = 1000000;
reqStr = '1000000';
catalog = 10000;
IDs = 1:catalog;
target = 100;

tStudent = [1.2 6.314 2.920 2.353 2.132 2.015 1.943 1.895 1.860 1.833 1.812 1.796];

% Effective values of simulated parameters

numSimulators = [2 3];
numScenarios = [1];
numCatalogs = [1];
numRatios = [1];
numLambdas = [1];
%numAlphas = [1 2 3 4];
numAlphas = [2 3 4];

% Input folder (change according to num req)
folder='/home/tortelli/Comparison_New_Simulators/Results/Single_Cache/R_1e6/logs/';
%folder='/home/tortelli/ndn-simulator-comparison/Results/logs/SINGLE_CACHE/';
ext='.out';

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


% Declaring structs for import

scenarioImport = struct;
contentID = struct;
hitDistance = struct;
limitRequests = struct;

% Initialization
for g = 1:length(numAlphas)
    for j = 1:length(numSimulators)
        contentID.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(numRequests, simRuns);
        hitDistance.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(numRequests, simRuns);
        limitRequests.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(simRuns,1);
    end
end

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


% Struct for Phit

pHitTotalRuns = struct;
pHitContentsRuns = struct; 
pMissContentsRuns = struct;
%pHitContentsNEW = struct;
%cdfHitContentsNEW = struct;


for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for v = 1:length(numLambdas)
            pHitTotalRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(simRuns,1);
            pHitContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, simRuns);
            pMissContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, simRuns);
        end 
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


% Calculating the final pHits, both Total and for each content
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


% Calculating the function f(x,che) = (che - x)/che, both Total and for each run.


% ***** RUNS ******
fForPhit_RUNS = struct;
for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        fForPhit_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, simRuns);
    end
end

for g=1:length(numAlphas)
    for j=1:length(numSimulators)
        for k = 1:simRuns
            for z = 1:catalog
                fForPhit_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,k) = (Che_Approx.(alphaStrCompl{numAlphas(g)}){1}(z,1) - pHitContentsRuns.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,k)) / Che_Approx.(alphaStrCompl{numAlphas(g)}){1}(z,1);
            end
        end
    end
end

% ***** MEAN ******

fForPhit_MEAN = struct;
for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
    fForPhit_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, 1);
    end
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for z = 1:catalog
            fForPhit_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1) = mean(fForPhit_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,:));
        end
    end
end



%% Calculate the Head Integral Error (HIE) and the Tail Integral Error (TIE)

% ***** RUNS ******

TAIL_INTEGRAL_ERROR_RUNS = struct;
HEAD_INTEGRAL_ERROR_RUNS = struct;

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        TAIL_INTEGRAL_ERROR_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, simRuns);
        HEAD_INTEGRAL_ERROR_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, simRuns);
    end
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for k = 1:simRuns
            for z = 1:catalog
                if z < catalog
                    TAIL_INTEGRAL_ERROR_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,k) = mean(abs(fForPhit_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z+1:catalog,k)));
                else
                    TAIL_INTEGRAL_ERROR_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,k) = fForPhit_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,k);
                end
            end
        end
    end
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for k = 1:simRuns
            for z = 1:catalog
                HEAD_INTEGRAL_ERROR_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,k) = mean(abs(fForPhit_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(1:z,k)));
            end
        end
    end
end

TAIL_INTEGRAL_ERROR_MEAN = struct;
TAIL_INTEGRAL_ERROR_STD = struct;
TAIL_INTEGRAL_ERROR_CONF = struct;
HEAD_INTEGRAL_ERROR_MEAN = struct;
HEAD_INTEGRAL_ERROR_STD = struct;
HEAD_INTEGRAL_ERROR_CONF = struct;

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        TAIL_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, 1);
        TAIL_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, 1);
        TAIL_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, 1);
        HEAD_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, 1);
        HEAD_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, 1);
        HEAD_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = zeros(catalog, 1);
    end
end

for g=1:length(numAlphas)
    for j = 1:length(numSimulators)
        for z = 1:catalog
            TAIL_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1) = mean(TAIL_INTEGRAL_ERROR_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,:));
            TAIL_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1) = std(TAIL_INTEGRAL_ERROR_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,:));
            TAIL_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1) = tStudent(1, simRuns-1) * TAIL_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1)/sqrt(simRuns);
            HEAD_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1) = mean(HEAD_INTEGRAL_ERROR_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,:));
            HEAD_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1) = std(HEAD_INTEGRAL_ERROR_RUNS.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,:));
            HEAD_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1) = tStudent(1, simRuns-1) * HEAD_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(z,1)/sqrt(simRuns);
        end
    end
end




% Calculating the Integral Errors for some representative percentile, i.e., p50, p75, p90, p95
TAIL_INTEGRAL_ERROR_p50_MEAN = struct;
TAIL_INTEGRAL_ERROR_p50_STD = struct;
TAIL_INTEGRAL_ERROR_p50_CONF = struct;
HEAD_INTEGRAL_ERROR_p50_MEAN = struct;
HEAD_INTEGRAL_ERROR_p50_STD = struct;
HEAD_INTEGRAL_ERROR_p50_CONF = struct;

TAIL_INTEGRAL_ERROR_p75_MEAN = struct;
TAIL_INTEGRAL_ERROR_p75_STD = struct;
TAIL_INTEGRAL_ERROR_p75_CONF = struct;
HEAD_INTEGRAL_ERROR_p75_MEAN = struct;
HEAD_INTEGRAL_ERROR_p75_STD = struct;
HEAD_INTEGRAL_ERROR_p75_CONF = struct;

TAIL_INTEGRAL_ERROR_p90_MEAN = struct;
TAIL_INTEGRAL_ERROR_p90_STD = struct;
TAIL_INTEGRAL_ERROR_p90_CONF = struct;
HEAD_INTEGRAL_ERROR_p90_MEAN = struct;
HEAD_INTEGRAL_ERROR_p90_STD = struct;
HEAD_INTEGRAL_ERROR_p90_CONF = struct;

TAIL_INTEGRAL_ERROR_p95_MEAN = struct;
TAIL_INTEGRAL_ERROR_p95_STD = struct;
TAIL_INTEGRAL_ERROR_p95_CONF = struct;
HEAD_INTEGRAL_ERROR_p95_MEAN = struct;
HEAD_INTEGRAL_ERROR_p95_STD = struct;
HEAD_INTEGRAL_ERROR_p95_CONF = struct;


f50_REQ_1mln_CONF = struct;
f50_REQ_1mln_HEAD_CONF = struct;
for g=1:length(numAlphas)
    for j = 1:length(numSimulators)        
        TAIL_INTEGRAL_ERROR_p50_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont50.(alphaStrCompl{numAlphas(g)}),1);
        TAIL_INTEGRAL_ERROR_p50_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont50.(alphaStrCompl{numAlphas(g)}),1);
        TAIL_INTEGRAL_ERROR_p50_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont50.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p50_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont50.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p50_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont50.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p50_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont50.(alphaStrCompl{numAlphas(g)}),1);

        TAIL_INTEGRAL_ERROR_p75_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont75.(alphaStrCompl{numAlphas(g)}),1);
        TAIL_INTEGRAL_ERROR_p75_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont75.(alphaStrCompl{numAlphas(g)}),1);
        TAIL_INTEGRAL_ERROR_p75_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont75.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p75_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont75.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p75_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont75.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p75_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont75.(alphaStrCompl{numAlphas(g)}),1);

        TAIL_INTEGRAL_ERROR_p90_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont90.(alphaStrCompl{numAlphas(g)}),1);
        TAIL_INTEGRAL_ERROR_p90_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont90.(alphaStrCompl{numAlphas(g)}),1);
        TAIL_INTEGRAL_ERROR_p90_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont90.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p90_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont90.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p90_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont90.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p90_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont90.(alphaStrCompl{numAlphas(g)}),1);
    
        TAIL_INTEGRAL_ERROR_p95_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont95.(alphaStrCompl{numAlphas(g)}),1);
        TAIL_INTEGRAL_ERROR_p95_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont95.(alphaStrCompl{numAlphas(g)}),1);
        TAIL_INTEGRAL_ERROR_p95_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = TAIL_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont95.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p95_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_MEAN.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont95.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p95_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_STD.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont95.(alphaStrCompl{numAlphas(g)}),1);
        HEAD_INTEGRAL_ERROR_p95_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)}) = HEAD_INTEGRAL_ERROR_CONF.(alphaStrCompl{numAlphas(g)}).(simulatorStr{numSimulators(j)})(cont95.(alphaStrCompl{numAlphas(g)}),1);
    end
end

save(stringOutput);