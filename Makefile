.PHONY: build
build:
	hugo

.PHONY: deploy
deploy:
	aws s3 rm s3://www.adrian-docs.com/ --recursive
	aws s3 sync ./public s3://www.adrian-docs.com/