{ CompositeDisposable } = require 'atom'
relative = require 'relative'

generateTag = (fileExtension, extension, relativePath, fileName, textEditor) ->
  type = undefined
  if fileExtension != extension and extension != 'img'
    textEditor.insertText '<!-- Converted from ' + fileExtension + ' -->\n'
  textEditor.insertText type = {
    'js': '<script src="' + relativePath.replace(fileExtension, extension) + '"></script>\n'
    'css': '<link href="' + relativePath.replace(fileExtension, extension) + '" rel="stylesheet">\n'
    'img': '<img src="' + relativePath + '" alt="' + fileName + '">\n'
  }[extension]
  return

intOrExtDrag = (currentFileName, fileExtension, relativePath, fileName, textEditor, selectedFiles, currentPath) ->
  scriptArray = ['js', 'jsx', 'coffee']
  linkArray = ['css', 'scss', 'less']
  imageArray = ['jpg', 'jpeg', 'png', 'apng', 'ico' ,'gif' ,'svg' ,'bmp' ,'webp']

  count = 0
  while count < selectedFiles.length
    selected = selectedFiles[count].file?.path || selectedFiles[count].path

    shouldGenerate = false
    for ext in atom.config.get('drag-relative-path.generateTagFileTypes')
      if currentFileName.endsWith(ext)
        shouldGenerate = true
        break

    if shouldGenerate
      if atom.config.get("drag-relative-path.relativeToPath")
        editor = atom.workspace.getActiveTextEditor()
        path = atom.project.relativizePath(editor.getPath())[0]
        currentPath = path + atom.config.get("drag-relative-path.relativeToPath")
      if scriptArray.includes(fileExtension)
        generateTag fileExtension, 'js', relative(currentPath, selected), fileName, textEditor
      else if linkArray.includes(fileExtension)
        generateTag fileExtension, 'css', relative(currentPath, selected), fileName, textEditor
      else if imageArray.includes(fileExtension)
        generateTag fileExtension, 'img', relative(currentPath, selected), fileName, textEditor
    else
      textEditor.insertText "'#{relative currentPath, selected}'" + '\n'
    count++
  return

module.exports =
  config:
    generateTagFileTypes:
      title: "File extensions to generate tags for"
      description: "Align trailing comments when aligning characters"
      type: "array"
      default: [
        "html","blade.php", "tpl", "twig"
      ]
    relativeToPath:
      title: "Generate tags relative to specific directory"
      description: "Generate tags relative to a specific (e.g., public) directory instead of the target file."
      type: "string"
      default: ''
  activate: (state) ->
      @subscriptions = new CompositeDisposable
      @subscriptions.add atom.workspace.observeTextEditors((textEditor) ->
        textEditorElement = atom.views.getView(textEditor)
        textEditorElement.addEventListener 'drop', (e) ->
          relativePath = undefined
          if e.dataTransfer.files.length
            files = e.dataTransfer.files
            i = 0
            while i < files.length
              file = files[i]
              f = file.name
              if f.indexOf(".") == -1
                return
              else
                currentPath = textEditor.buffer.file.path
                unless typeof currentPath isnt "undefined" then return
                currentFileName = textEditor.buffer.file.getBaseName()
                extFileExtension = file.path.split('.').pop()
                relativize = atom.project.relativizePath(file.path)
                relativePath = relative(currentPath, relativize[1])
                fileName = relativePath.split('/').slice(-1).join().split('.').shift()
                e.preventDefault()
                e.stopPropagation()
                intOrExtDrag currentFileName, extFileExtension, relativePath, fileName, textEditor, files, currentPath
                i++
          else
            selectedFiles = document.querySelectorAll('.file.entry.list-item.selected')
            selectedSpan = document.querySelector('.file.entry.list-item.selected>span')
            if selectedFiles and selectedSpan # check if a file is dropped
              dragPath = selectedSpan.dataset.path
              currentPath = textEditor.buffer.file.path
              unless typeof currentPath isnt "undefined" then return
              currentFileName = textEditor.buffer.file.getBaseName()
              relativePath = relative(currentPath, dragPath)
              fileName = relativePath.split('/').slice(-1).join().split('.').shift()
              intFileExtension = relativePath.split('.').pop()
              intOrExtDrag currentFileName, intFileExtension, relativePath, fileName, textEditor, selectedFiles, currentPath
          return
      )
      return

deactivate: ->
  @subscriptions.dispose()
