# My_third_post


# This is my third post

如果希望单独控制源文档和生成的网页文档的版本历史，可以使用单独建立一个gh-pages branch的方法托管到Github Pages——先将/public子目录添加到.gitignore中，让master branch忽略其更新，然后在本地和Github端添加一个名为gh-pages的branch：

为了提高每次发布的效率，可以将下述命令存在脚本中，每次只需要运行该脚本即可将gh-pages branch中的文章发布到Github的repo中：