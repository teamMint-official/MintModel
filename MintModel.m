function [v, v_shaped, v_posed, rot_J_global] = MintModel(Core, beta, theta, Shape_Para, Exp_Para)
    % shapedirs, posedirs, regJoint, weights, kintree
    shapeParam = Core.w_shp*Shape_Para;
    shapeParam = reshape(shapeParam, [3 159645/3]);
    shapeParam = shapeParam';
    shapeFace = zeros(53490, 3);
    for i = 1:length(shapeParam)
        shapeFace(Core.trimIndex(i), :) = shapeParam(i, :);
    end
    shapeFace = shapeFace(Core.faceIdx, :);

    expParam = Core.w_exp*Exp_Para;
    expParam = reshape(expParam, [3 159645/3]);
    expParam = expParam';
    expFace = zeros(53490, 3);
    for i = 1:length(expParam)
        expFace(Core.trimIndex(i), :) = expParam(i, :);
    end
    expFace = expFace(Core.faceIdx, :);

    Core.meanVerts(1:27583, :) = Core.meanVerts(1:27583, :) + shapeFace + expFace;

    %% Shape PCA
    v_shaped = squeeze(sum(permute(Core.shapeDirs, [3 1 2]) .* beta)) + Core.meanVerts;

    %% Joint Regressor
    J = Core.regJoint * v_shaped;   

    %% Pose Regressor
    nPosedir = size(Core.poseDirs, 3); % 23 x 9 = 207
    dTheta = zeros(nPosedir, 1);
    for i = 2:length(theta) % Except Global Transformation
        dTemp = rod(theta(i,:)) - eye(3);
        dTheta((i-2)*9+(1:9)) = dTemp(:);
    end
    v_posed = squeeze(sum(permute(Core.poseDirs, [3 1 2]) .* dTheta)) + v_shaped;

    %% Linear Blend Skinning
    % Get Rotation Matrix along the Joint
    rot_J = zeros(4, 4, length(Core.kinTree)); % 4 x 4 x 24
    rot_J(:, :, 1) = rod(theta(1, :), J(1,:));
    for j = 2:length(Core.kinTree)
        childRot = rod(theta(j, :), (J(j, :) - J((Core.kinTree(1, j)+1), :)));
        rot_J(:,:,j) = rot_J(:, :, (Core.kinTree(1, j)+1)) * childRot;
    end

    rot_J_global = rot_J; % Global Rotation matrix of the Joint
    for i = 1:length(Core.kinTree)
        rot_J(:, :, i) = rot_J(:, :, i) - [zeros(4,3) (rot_J(:,:,i) * [J(i,:) 0]')];
    end

    %% Make Skinned Vertices
    nJoint = size(Core.blendWeights, 2); % 24
    nVertex = size(Core.blendWeights, 1); % 6890

    % rot_J [(4 x 4) x 24] * weights [(24 x 6890)']
    % Jtr = squeeze(rot_J_global(1:3, 4, :)); 
    T = reshape(reshape(rot_J, [16, nJoint]) * Core.blendWeights', [4, 4, nVertex]); % 4 x 4 x 6890

    rest_shape_h = repmat([v_posed ones(length(v_posed),1)], 1, 1, 4); % 6890 x 4 x 4
    v = squeeze(sum(permute(T, [3 2 1]) .* rest_shape_h, 2))';
    v = v(1:3, :) ./ v(4, :); % Homogenous to Cartesian
    v = v(1:3, :)'; % Final Src vertices set

end

function R = rod(V, J)
    if all(V == 0)
        R = eye(3);
    else
        theta=sqrt(V(1)^2 + V(2)^2 + V(3)^2);
        omega=[0 -V(3) V(2); V(3) 0 -V(1); -V(2) V(1) 0];
        R = eye(3) + (sin(theta)/theta)*omega + ((1-cos(theta))/theta^2)*(omega*omega);
    end
    if (nargin > 1)
        if size(J, 2) == 3
            J = J';
        end       
        R = [R J];
        R = [R; [0 0 0 1]];
    end
end

