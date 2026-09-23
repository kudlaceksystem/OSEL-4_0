filepn1 = 'd://Kudlacek/Literature/Maths/Mathematical Analysis/Demlova/Vyrokova logika - Prednaska';
url1 = 'http://math.feld.cvut.cz/demlova/teaching/dml/pred';
for k = 1 : 50
    k
    websave([filepn1, num2str(k, '%2.2d'), '.pdf'], [url1, num2str(k, '%2.2d'), '.pdf']);
end
