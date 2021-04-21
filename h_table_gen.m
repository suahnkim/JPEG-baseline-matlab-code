%Description: 
% This generates optimized Huffman table based on the given statistics of
% the symbols. During JPEG decoding, Huffman table is generated from list of possible values and
% number of Huffman codes of certain length (1~16). Thus, code length of each symbols are calculated first. Then, the code lengths are adjusted so that they are between 1 and 16. And then, based on code length generate codewords for each code length   
%Input: Frequency of symbols
%Output: Huffman table of the symbols 
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function [h_table]=h_table_gen(frequency)
%% Generate Code lengths based on the probability table
FQ=[transpose(0:255) zeros(256,1)];
FQ(1+hex2dec(frequency(:,1)),2)=cell2mat(frequency(:,2))/sum(cell2mat(frequency(:,2)));
CS=[transpose(0:256) zeros(257,1)];
OT=-1*ones(257,2);
OT(:,1)=0:256;
LEVEL=[transpose(0:255) zeros(256,1)];

%Code size CS: Code size of symbol V
while 1
    FQ_nz=FQ(FQ(:,2)>0,:);
    
    V_right=max(FQ_nz(FQ_nz(:,2)==min(FQ_nz(:,2)),1)); % if there are multiple equal frequencies choose the largest V
    temp1=FQ_nz(FQ_nz(:,1)~=V_right,:);
    V_left=max(temp1(temp1(:,2)==min(temp1(:,2)),1)); %if there are multiple equal frequencies choose the largest V
    
    if isempty(V_left)
        if isequal(OT(:,2),-1*ones(257,1))
            CS(CS(:,1)==V_right,2)=CS(CS(:,1)==V_right,2)+1;
        end
        break
    end
    
    if LEVEL(LEVEL(:,1)==V_left,2) > LEVEL(LEVEL(:,1)==V_right,2) 
        temp2=V_right;
        V_right=V_left;
        V_left=temp2;
    end
    
    FQ(FQ(:,1)==V_right,2)=FQ(FQ(:,1)==V_right,2)+FQ(FQ(:,1)==V_left,2); % add frequencies of V1 and V2 together
    FQ(FQ(:,1)==V_left,2)=0;
    
    CS(CS(:,1)==V_right,2)=CS(CS(:,1)==V_right,2)+1;
    LEVEL(LEVEL(:,1)==V_right,2)=max(LEVEL(LEVEL(:,1)==V_left,2),LEVEL(LEVEL(:,1)==V_right,2))+1;
    while OT(OT(:,1)==V_right,2)~=-1
        V_right=OT(OT(:,1)==V_right,2);
        CS(CS(:,1)==V_right,2)=CS(CS(:,1)==V_right,2)+1;
    end
    OT(OT(:,1)==V_right,2)=V_left;

    CS(CS(:,1)==V_left,2)=CS(CS(:,1)==V_left,2)+1;
    
    while OT(OT(:,1)==V_left,2)~=-1
        V_left=OT(OT(:,1)==V_left,2);
        CS(CS(:,1)==V_left,2)=CS(CS(:,1)==V_left,2)+1;
    end
end
CS=sortrows(CS(CS(:,2)~=0,:),2);
[CS_length,~]=size(CS);
temp=tabulate(CS(:,2));
BITS=zeros(32,1);
BITS(temp(:,1))=temp(:,2);

%% Adjust BITS: this procedure ensures that no huffman codes are longer than 16 bits.
for I =32:-1:16
    while 1
        if BITS(I)>0
            J=I-1;
            while 1
                J= J-1;
                if BITS(J)>0
                    break
                end
            end
            BITS(I)=BITS(I)-2;
            BITS(I-1)=BITS(I-1)+1;
            BITS(J+1)=BITS(J+1)+2;
            BITS(J)=BITS(J)-1;
        else
            break
        end
    end
end

% Following step ensures that there are odd numbers of the largest
% Huffman code length. I don't exactly understand why this is a requirement
%, but from the experiments I have conducted, this has to be true for the
%decoder to successfully produce the Huffman table. (note: standard does not
%specify how to generate the Huffman code length, as long as it is decodable by the JPEG compliant decoders, it is fine) 
largest_codeword_length=find(BITS>0,1,'last');
if mod(BITS(largest_codeword_length),2)==0 && BITS(largest_codeword_length)>0
    BITS(largest_codeword_length)=BITS(largest_codeword_length)-1;
    BITS(largest_codeword_length+1)=1;
end

%% Generates Huffman table based on the code length 
largest_codeword_length=find(BITS>0,1,'last');
h_table=[dec2hex(CS(:,1)) strings(CS_length,1) strings(CS_length,1)];
h_table_length=0;
for i1=1:largest_codeword_length
    if i1==1
        L_code=["0" "1"];
    else
        [~,L_code_length]=size(L_code);
        temp3=[];
        for i2=1:L_code_length
            temp1=strcat(L_code(i2),"0");
            temp2=strcat(L_code(i2),"1");
            temp3=[temp3 temp1 temp2];
        end
        L_code=temp3;
    end
    j1_max=BITS(i1);
    if not(isempty(j1_max))
    for j1=1:j1_max
        h_table_length=h_table_length+1;
        h_table(h_table_length,2)=num2str(length(char(L_code(j1))));
        h_table(h_table_length,3)=L_code(j1);
    end
    L_code(1:j1_max)=[];
    end
end
end
