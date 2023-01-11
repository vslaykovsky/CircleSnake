ARG BASE_IMAGE=nvcr.io/nvidia/pytorch:21.07-py3
FROM $BASE_IMAGE
ARG BASE_IMAGE

COPY lib/csrc environment.yml CircleSnake/

# COPY configs external lib tools environment.yaml CircleSnake

WORKDIR CircleSnake

# Create the environment:
RUN conda env create -n CircleSnake -f environment.yml

# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "CircleSnake", "/bin/bash", "-c"]

## Make RUN commands use the new environment:
# RUN echo "conda activate CircleSnake" >> ~/.bashrc
# SHELL ["/bin/bash", "--login", "-c"]

RUN cd dcn_v2/ && \
    python setup.py build_ext --inplace && \
    cd ../extreme_utils && \
    python setup.py build_ext --inplace && \
    cd ../roi_align_layer && \
    python setup.py build_ext --inplace



ENV CLOUDSDK_INSTALL_DIR /usr/local/gcloud/
RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin
COPY gcloud.json .
RUN gcloud auth login --cred-file=gcloud.json
RUN gsutil ls gs://vslaykovsky

RUN pip install wandb tensorboard

# COPY dla34-ba72cf86.pth /root/.cache/torch/hub/checkpoints/dla34-ba72cf86.pth
COPY configs configs 
COPY external external 
COPY lib lib
COPY tools *.py ./


ENTRYPOINT gsutil -m cp gs://vslaykovsky/data.zip . && gsutil -m cp gs://vslaykovsky/annotations_circlenet.zip . && mkdir -p /root/.cache/torch/hub/checkpoints/ && gsutil -m cp gs://vslaykovsky/dla34-ba72cf86.pth /root/.cache/torch/hub/checkpoints/ && \
    mkdir -p data/stemInstance/annotations && \
    unzip data.zip -d data/stemInstance && \
    unzip annotations_circlenet.zip -d data/stemInstance/annotations && \
    echo "finished uncompressing data" && \
    conda run -n CircleSnake python train_net.py --cfg_file configs/coco_circlesnake.yaml model stemInstance train.dataset CocoTrain test.dataset CocoVal

# COPY data.zip annotations_circlenet.zip .
# ENTRYPOINT \
#     mkdir -p data/stemInstance/annotations && \
#     unzip data.zip -d data/stemInstance && \
#     unzip annotations_circlenet.zip -d data/stemInstance/annotations && \
#     conda run -n CircleSnake python train_net.py --cfg_file configs/coco_circlesnake.yaml model stemInstance train.dataset CocoTrain test.dataset CocoVal
