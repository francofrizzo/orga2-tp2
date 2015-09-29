function [x, y, e] = leer_datos(file)
    data = fopen(file);
    cant = fscanf(data, '%d', 1);
    cant = cant + 1;
    A = fscanf(data, '%d', [cant Inf]);
    A = sort(A');

    x = A(:,1);
    d = A;
    d(:,1) = [];
    y = mean(d, 2);
    e = std(d, 1, 2);

    fclose(data);
end
