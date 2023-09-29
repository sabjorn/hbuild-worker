# HBuild-Worker
A Docker image based on [aaronsmithtv/hbuild](github.com/aaronsmithtv/Houdini-Docker) with extra configuration to allow for easily running `python` with access to Houdini's `hou`.

The goal of this project is to make it easier to integrate  with CI/CD build pipeliens for programatically generating Houdini assets. 

The image is available on Docker Hub: [sabjorn/hbuild-worker](https://hub.docker.com/r/sabjorn/hbuild-worker)

## Example Usage
The following command will launch all the necessary services within the Docker container and jump the user into a python3 session:
```
docker run -it --rm \
    -e SIDEFX_CLIENT=<client id> \
    -e SIDEFX_SECRET=<client secret> \
    -e HOUDINI_USERNAME=<username or email> \
    -e HOUDINI_PASSWORD=<houdini password> \
    -v <local file directory>:/work
    sabjorn/hbuild-worker python3
```

Within this python3 session, users can build nodes and export an HDA, e.g.:
```
import hou

geo = hou.node("/obj").createNode("geo")
subnet = geo.createNode("subnet")

sphere_node = subnet.createNode("sphere")
output_node = subnet.createNode("output")

output_node.setInput(0, sphere_node)

subnet.layoutChildren()

hda_node = subnet.createDigitalAsset(name="my hda", description="example HDA", compress_contents=True, version="1.0.0", save_as_embedded=False, ignore_external_references=True, change_node_type=True, create_backup=False)
hda_def =  hda_node.type().definition()
hda_def.save("my_hda.hda")
```
