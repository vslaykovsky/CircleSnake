import torch
import torch.nn as nn

from lib.config import cfg
from lib.utils import data_utils, net_utils
from lib.utils.snake import snake_decode

from .dla import DLASeg
from .evolve import Evolution


class Network(nn.Module):
    def __init__(self, num_layers, heads, head_conv=256, down_ratio=4, det_dir=""):
        super(Network, self).__init__()

        self.dla = DLASeg(
            "dla{}".format(num_layers),
            heads,
            pretrained=True,
            down_ratio=down_ratio,
            final_kernel=1,
            last_level=5,
            head_conv=head_conv,
        )
        self.gcn = Evolution()

    def decode_detection(self, output, h, w):
        ct_hm = output["ct_hm"]
        radius = output["radius"]
        reg = output["reg"]

        ct, detection = snake_decode.decode_ct_hm_circle(ct_hm, radius, reg)
        detection = data_utils.circle_clip_to_image(detection, h, w)
        output.update({"ct": ct, "detection": detection})
        return ct, detection

    def use_gt_detection(self, output, batch):
        _, _, height, width = output["ct_hm"].size()
        ct_01 = batch["ct_01"].byte()

        ct_ind = batch["ct_ind"][ct_01]
        xs, ys = ct_ind % width, ct_ind // width
        xs, ys = xs[:, None].float(), ys[:, None].float()
        ct = torch.cat([xs, ys], dim=1)

        radius = batch["radius"][ct_01]
        score = torch.ones([len(radius)]).to(radius)[:, None]
        ct_cls = batch["ct_cls"][ct_01].float()[:, None]
        detection = torch.cat([xs, ys, radius, score, ct_cls], dim=1)

        output["ct"] = ct[None]
        output["detection"] = detection[None]

        return output

    def forward(self, x, batch=None):
        output, cnn_feature = self.dla(x)
        output["ct_hm"] = data_utils.sigmoid(output["ct_hm"])

        with torch.no_grad():
            ct, detection = self.decode_detection(output, cnn_feature.size(2), cnn_feature.size(3))
        if cfg.use_gt_det:
            self.use_gt_detection(output, batch)
        output = self.gcn(output, cnn_feature, batch)
        return output


def get_network(num_layers, heads, head_conv=256, down_ratio=4, det_dir=""):
    network = Network(num_layers, heads, head_conv, down_ratio, det_dir)
    return network
