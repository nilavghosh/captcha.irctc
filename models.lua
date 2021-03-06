require 'nn';
require 'MultiCrossEntropyCriterion'

local models = {}
function models.cnnModel(k,c)
    local k = k or 5
    local c = c or 36
-- Will use "ceil" MaxPooling because we want to save as much
-- space as we can
    local vgg = nn.Sequential()
    vgg:add(nn.Reshape(1,50,170))

    local backend_name = 'nn'

    local backend = nn
    local MaxPooling = backend.SpatialMaxPooling

    -- building block
    local function ConvBNReLU(nInputPlane, nOutputPlane)
      vgg:add(backend.SpatialConvolution(nInputPlane, nOutputPlane, 3,3, 1,1, 1,1))
      vgg:add(nn.SpatialBatchNormalization(nOutputPlane,1e-3))
      vgg:add(backend.ReLU(true))
      return vgg
    end
    ConvBNReLU(1,64)--:add(nn.Dropout(0.3,nil,true))
    ConvBNReLU(64,64)
    vgg:add(MaxPooling(2,2,2,2):ceil())

    ConvBNReLU(64,128)--:add(nn.Dropout(0.4,nil,true))
    ConvBNReLU(128,128)
    vgg:add(MaxPooling(2,2,2,2):ceil())

    ConvBNReLU(128,256)--:add(nn.Dropout(0.4,nil,true))
    ConvBNReLU(256,256)--:add(nn.Dropout(0.4,nil,true))
    ConvBNReLU(256,256)
    vgg:add(MaxPooling(2,2,2,2):ceil())

    ConvBNReLU(256,512)--:add(nn.Dropout(0.4,nil,true))
    ConvBNReLU(512,512)--:add(nn.Dropout(0.4,nil,true))
    ConvBNReLU(512,512)
    vgg:add(MaxPooling(2,2,2,2):ceil())

    -- In the last block of convolutions the inputs are smaller than
    -- the kernels and cudnn doesn't handle that, have to use cunn
    backend = nn
    ConvBNReLU(512,512)--:add(nn.Dropout(0.4,nil,true))
    ConvBNReLU(512,512)--:add(nn.Dropout(0.4,nil,true))
    ConvBNReLU(512,512)
    vgg:add(MaxPooling(2,2,2,2):ceil())
    vgg:add(nn.View(512*2*6))

    classifier = nn.Sequential()
    --classifier:add(nn.Dropout(0.5,nil,true))
    classifier:add(nn.Linear(512*2*6,512))
    classifier:add(nn.BatchNormalization(512))
    classifier:add(nn.ReLU(true))
    --classifier:add(nn.Dropout(0.5,nil,true))
    classifier:add(nn.Linear(512,k*c))
    vgg:add(classifier)
    vgg:add(nn.Reshape(k,c))
    return vgg,nn.MultiCrossEntropyCriterion()
end

function models.resnet(depth)
    local opt = {
      cudnn = "fastest",
      LR = 0.1,
      nThreads = 2,
      nClasses = 0,
      batchSize = 32,
      testOnly = false,
      netType = "resnet",
      resetClassifier = false,
      shortcutType = "A",
      gen = "t7",
      nGPU = 1,
      depth = depth or 34,
      weightDecay = 0.0001,
      data = "",
      dataset = "irctc",
      epochNumber = 1,
      manualSeed = 2,
      resume = "none",
      optimState = "none",
      nEpochs = 1,
      tenCrop = false,
      shareGradInput = false,
      backend = "cudnn",
      momentum = 0.9,
      retrain = "none"
    }
    local resnet = require 'models/init'
    local net,ct = resnet.setup(opt, checkpoint)
    local net = net:cuda()
    local ct = nn.MultiCrossEntropyCriterion():cuda()
    return net,ct
end


function models.resnetAug(depth)
    local opt = {
      cudnn = "fastest",
      LR = 0.1,
      nThreads = 2,
      nClasses = 0,
      batchSize = 32,
      testOnly = false,
      netType = "resnet",
      resetClassifier = false,
      shortcutType = "A",
      gen = "t7",
      nGPU = 1,
      depth = depth or 34,
      weightDecay = 0.0001,
      data = "",
      dataset = "irctcAug",
      epochNumber = 1,
      manualSeed = 2,
      resume = "none",
      optimState = "none",
      nEpochs = 1,
      tenCrop = false,
      shareGradInput = false,
      backend = "cudnn",
      momentum = 0.9,
      retrain = "none"
    }
    local resnet = require 'models/init'
    local net,ct = resnet.setup(opt, checkpoint)
    local net = net:cuda()
    local ct = nn.MultiCrossEntropyCriterion():cuda()
    return net,ct
end

return models
