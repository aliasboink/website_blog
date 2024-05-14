+++
title = 'ArgoCD on RaspberryPi 4'
date = 2024-04-14T15:00:00+03:00
draft = false
+++

## Introduction

I was looking for a reason to use [Kubernetes](https://kubernetes.io/). I got a Raspberry Pi 4 to host a "cluster" (1 node) on - that's plenty for an educational projects with the possibility of expanding it in the futrure. It's go time.

Since I want everything in GitHub the best tool for deployment on Kubernetes seems to be a combination of `Helm` and `ArgoCD`. That's also thanks to the fact that I have experience with them, which may or may not make me biased. :)

To that end, the following technologies will be used: `Kubernetes` will be used for the orchestration of the containers, `ArgoCD` for deployment, everything will be nicely packed in `Helm` charts, and the code will all be on `GitHub`. Anything more will be application specific.

## How to use Kubernetes with Raspberry Pi?

Here there are several options. The ones I gave a brief look at being:
- MicroK8s
- k3s
- minikube
- kind 
- k0
- kubeadm
- and more...

Two of these are best fit for local development (minikube and kind). The rest are a good depending on what you want. I didn't go in-depth in all of them, but briefly gave them a look and flipped a coin that landed on `k3s`. The official documentation is nice and comprehensive with simple illustrations. It's advertisment for IoT deployments - it fits the bill just fine.

The installation itself was quite easy using the [official documentation](https://docs.k3s.io/installation). There were a couple of hiccups that were easily fixed.

## ArgoCD on K3s

ArgoCD and Kubernetes make a surprisingly good pair - one strange benefit I enjoy a fair bit is that I can look at the configuration or logs of applications both with `ArgoCD` and with Kubernetes tools, specifically `k9s` in my case.

### Design

For the purpose of using GitHub as much as possible - I needed to create what is known as a "root app". Some quick Googling lead to the fact that this is a very common well known pattern documented by ArgoCD right [here](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)!

The reason why this pattern is powerful is because it allows you to have applications picked up from a git repository that you can easily modify. You can add applications, you can remove applications, you can add a few extra resources that may be required for this specific cluster - you can do whatever all via traceable git commits.

You can choose the amount of root apps you have. This is useful due to the fact that if you mess up the manifest of any one application - the root app will not sync nor update any of the other applications. This is an issue when working with other people on the same cluster on different applications. 

In my case - one root app is enough. I don't ever see myself allowing anyone else to deploy applications on the Raspberry Pi 4 K3s cluster. Not willingly at least.

### Installation 

The process I followed here was the following:
1. Manually deploy on a local Kind cluster
2. Manually deploy on the K3s cluster
3. Manually deploy on the K3s cluster with the GitHub repository code

I prefer to have (1) due to two reasons: I am comfortable running kind clusters locally and an `amd64` architecture may prove easier to work with initally. For (2) I followed the exact same steps in (1) successfully. For (3) the code writing starts [here](https://github.com/aliasboink/raspberrypi_argocd_module). The only caveat is that I have a small script to load the `ssh_key`as an environment variable - this has to be ran before the deployment. Normally this would be better dynamically pulled from an external vault, but given the scale of the project I'd rather a small extra step.

## Set up Gitea 

Perfect. I got ArgoCD running. What to do now?

The answer is: scroll through the Bitnami helm charts to find something interesting to deploy. Mastodon seems nice, but it would be entirely useless. Discourse seems quite nice for building a small community, but it doesn't have `arm64` support. Gitea seems quite good if I wish to ever back up my code from GitHub in case... it goes down along with the entire internet? Sounds good to me!

I managed to successfully deploy Gitea and wishing to further tinker with it I had realized that [it only allways for one replica](https://github.com/bitnami/charts/blob/main/bitnami/gitea/templates/deployment.yaml#L22). Thus, I scratched this and went for the [gitea/helm-chart on Gitea](https://gitea.com/gitea). 

## Configure Gitea

Set it up, changed ports around a bit, and got it successfully running in the cluster. The setup works! 

Now, since I don't wish for my Raspberry Pi 4 to be set aflame I have to make Gitea be invite only. For the sake of security, I also wish for the credentials of the admin user to not be part of the `values.yaml` file. Gitea allows giving the credentials via a Kubernetes Secret, but unfortunately _for some reason_ it doesn't allow you to set the admin email in the Kubernetes Secret as well. That has to be done through the `values.yaml` file.

## Connect the Raspberry Pi 4 to the internet

The first thought that came to mind was port forwarding. This would come with the "downside" of having to harden my local network - but all in all it sounds like a fun challenge. Unfortunately, my internet provider seems to be using CGNAT and to be able to expose my `Raspberry Pi 4` a number of calls with the internet provider and possibly a chance of routers would be necessary - thus another option was chosed.

[CloudFlare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) fit the bill perfectly well. At the risk of sounding like an advertisment - the tunnel was extremely easy to set up and requires no further hardening as everything goes through a `CloudFlare Proxy`. Should be good if you trust CloudFlare with your traffic data. :)


## Where is Gitea accessible?

You can access Gitea [here](https://gitea.adrian-docs.com/)!