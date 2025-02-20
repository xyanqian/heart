names = {'week6.5_1' 'week6.5_2'};
MinPieProb = .05;
MinReads = 5;
MinReadsProb = 0.1;

for s = 1:2
    
    load(['F:\FetalHeartManuscript\CellCalling\20190603\o_heart_cellcall_' names{s} '_20190603.mat']);
    load(['F:\FetalHeartManuscript\CellCalling\20190603\CellMap_' names{s} '_20190603.mat'], 'IncludeSpot');
    
    %% take only reads in tissue
    I = imread(['F:\FetalHeartManuscript\' names{s} '\issSingleCell\base1_c1_ORG.tif']);
    I = imbinarize(I, graythresh(I));
    I = imdilate(I, strel('disk', 10));
    I = imclose(I, strel('disk', 70));
    I = imfill(I, 'holes');
    I = imdilate(I, strel('disk', 5));
%     f=figure; imshow(I); waitfor(f);
    
       
    %% fix indexing
    thesereads = find(IncludeSpot);
    thesecells = sum(o.pSpotCell(:,1:end-1), 1) > MinReads;
    intissue = logical(readsinroi(fliplr(o.SpotGlobalYX(IncludeSpot,:)), I));
    
    %% iss.json
    fid = fopen(['..\dashboard\data\img\' names{s} '\iss.json'], 'w');
    fprintf(fid, '[');
    
    for i = find(thesecells)
        fprintf(fid, '{"Cell_Num":%d,"Y":%.1f,"X":%.1f,',...
            i, o.CellYX(i,1), size(I,2)-o.CellYX(i,2));
        children = find(full(o.pSpotCell(:,i)) > MinReadsProb);
        if ~isempty(children)
            genes = o.GeneNames(o.SpotCodeNo(thesereads(children)));
            [uGenes, ~, iGene] = unique(genes);
            
            fmt = lineformat('"%s"', length(uGenes));
            fprintf(fid, ['"Genenames":[' strrep(fmt, '\n', '],')], uGenes{:});
            
            fmt = lineformat('%.3f', length(uGenes));
            fprintf(fid, ['"CellGeneCount":[' strrep(fmt, '\n', '],')],...
                grpstats(full(o.pSpotCell(children,i)), iGene, 'sum'));
        else
            fprintf(fid, '"Genenames":[],"CellGeneCount":[],');
        end
        
        celltype = o.pCellClass(i,:);
        if nnz(celltype > MinPieProb)
            fmt = lineformat('"%s"', nnz(celltype > MinPieProb));
            fprintf(fid, ['"ClassName":[' strrep(fmt, '\n', '],')], o.ClassNames{celltype > MinPieProb});
            fmt = lineformat('%.3f', nnz(celltype > MinPieProb));
            fprintf(fid, ['"Prob":[' strrep(fmt, '\n', ']}')], celltype(celltype> MinPieProb));
        else
            fprintf(fid, '"ClassName":[],"Prob":[],');
        end
        
        if i < find(thesecells, 1, 'last')
            fprintf(fid, ',');
        else
            fprintf(fid, ']');
        end
    end
    fclose(fid);
    
    %% dapi_overlays.json
    
    
    fid = fopen(['..\dashboard\data\img\' names{s} '\Dapi_overlays.json'], 'w');
    fprintf(fid, '[');
    for i = find(intissue)'
        
        fprintf(fid, '{"Gene":"%s","Expt":%d,"y":%.1f,"x":%.1f,',...
            o.GeneNames{o.SpotCodeNo(thesereads(i))}, o.SpotCodeNo(thesereads(i)),...
            o.SpotGlobalYX(thesereads(i),1), size(I,2)-o.SpotGlobalYX(thesereads(i),2));
        
        pSpotCell = full(o.pSpotCell(i,1:end-1));
        [p, parent] = sort(pSpotCell, 'descend');
        
        if pSpotCell(parent(1)) > MinPieProb && thesecells(parent(1))
            
            fprintf(fid, '"neighbour":%d,', parent(1));
%             fmt = lineformat('%d', nnz(p > 0.001));
%             fprintf(fid, ['"neighbour_array":[' strrep(fmt, '\n', '],')], parent(1:nnz(p>0.001)));
%             fmt = lineformat('%f', nnz(p>0.001));
%             fprintf(fid, ['"neighbour_prob":[' strrep(fmt, '\n', ']}')], p(1:nnz(p>0.001)));
            fprintf(fid, '"neighbour_array":[%d],', parent(1));
            fprintf(fid, '"neighbour_prob":[%.3f]}', p(1));
            
        else
            fprintf(fid, '"neighbour":null,"neighbour_array":null,"neighbour_prob":null}');
        end
        
        if i < find(intissue, 1, 'last')
            fprintf(fid, ',');
        else
            fprintf(fid, ']');
        end
    end
    fclose(fid);
end
    