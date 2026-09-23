function createEmailFromName
names = ["Pavel Mareš";
"Hana Kubová";
"Jaroslava Folbergerová";
"Anna Mikulecká";
"Šárka Rùžièková";
"Eva Lažková";
"Irna Nešev";
"Blanka Èejková";
"Ivana Rabasová";
"Antonín Pošusta"];
names = removediacritics(names);
names = lower(names);
names = strrep(names, " ", ".");
names = names + "@fgu.cas.cz";
emailAdress = names(1);
for k = 2 : length(names)
    emailAdress = emailAdress + "; " + names(k);
end
disp(emailAdress)
end

function [clean_s] = removediacritics(s)
%REMOVEDIACRITICS Removes diacritics from text.
%   This function removes many common diacritics from strings, such as
%     á - the acute accent
%     ? - the grave accent
%     â - the circumflex accent
%     ü - the diaeresis, or trema, or umlaut
%     ? - the tilde
%     ç - the cedilla
%     ? - the ring, or bolle
%     ? - the slash, or solidus, or virgule

% uppercase
s = regexprep(s,'(?:Á|?|Â|?|Ä|?)','A');
s = regexprep(s,'(?:?)','AE');
s = regexprep(s,'(?:ß)','ss');
s = regexprep(s,'(?:Ç|È)','C');
s = regexprep(s,'(?:?)','D');
s = regexprep(s,'(?:É|?|?|Ë)','E');
s = regexprep(s,'(?:Í|?|Î|?)','I');
s = regexprep(s,'(?:?)','N');
s = regexprep(s,'(?:Ó|?|Ô|Ö|?|?)','O');
s = regexprep(s,'(?:?)','OE');
s = regexprep(s,'(?:Ú|?|?|Ü|Ù)','U');
s = regexprep(s,'(?:Ý|?)','Y');
s = regexprep(s,'(?:Š)','S');
s = regexprep(s,'(?:Ž)','Z');
s = regexprep(s,'(?:Ø)','R');

% lowercase
s = regexprep(s,'(?:á|?|â|ä|?|?)','a');
s = regexprep(s,'(?:?)','ae');
s = regexprep(s,'(?:ç|è)','c');
s = regexprep(s,'(?:?)','d');
s = regexprep(s,'(?:é|?|?|ë)','e');
s = regexprep(s,'(?:í|?|î|?)','i');
s = regexprep(s,'(?:?)','n');
s = regexprep(s,'(?:ó|?|ô|ö|?|?)','o');
s = regexprep(s,'(?:?)','oe');
s = regexprep(s,'(?:ú|?|ü|?|ù)','u');
s = regexprep(s,'(?:ý|?)','y');
s = regexprep(s,'(?:š)','s');
s = regexprep(s,'(?:ž)','z');
s = regexprep(s,'(?:ø)','r');

% return cleaned string
clean_s = s;
end