classdef filters
    %FILTERS Creates a filter based on the name
    %Creates a filter mask of different types

    properties
        Type % type of the filter
        Size {mustBeNumericOrLogical} % size of the filter or logical value false if not used
        Sigma {mustBeNumericOrLogical} % sigma or the logical value false if not used
    end

    methods
        function obj = filters(type, size, sigma)
            %FILTER Construct an instance of this class
            %   Creates the filter object
            obj.Type = type;
            obj.Size = size;
            obj.Sigma = sigma;
        end

        function mask = make_filter(obj)
            %MAKE_FILTER Creates a filter mask
            %   Creates a mask of chosen filter type
            switch obj.Type
                case 'gauss'
                    mask = gauss_filter(obj);
                otherwise
            end
        end

        function mask = gauss_filter(obj)
            %GAUSS_FILTER Returns a gaussian filter mask
            % Creates a gaussian filter mask with the given size and sigma
            % Substract 1 from filter size, because we have to calculate
            % coordinates
             size=[obj.Size, obj.Size];
             sigma=[obj.Sigma, obj.Sigma];
             mask = images.internal.createGaussianKernel(sigma, size);
        end

    end
end

