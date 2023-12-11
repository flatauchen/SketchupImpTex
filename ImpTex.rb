=begin
#===================================================================#
#	Plugin para importação de materiais com a possibilidade de		#
#	importar todas as imagens de uma pasta ou selecionar apenas		#
#	um arquivo de imagem com suporte para arquivos JPG e PNG.		#
#	Desenvolvido por: Flavio Tauchen								#
#===================================================================#
=end
# ImpTex.rb
require 'sketchup.rb'
require 'extensions.rb'

module FlaTauchen
	module TiImpTex

		EXTVERSION		= "1.0.1"
		EXTTITLE		= "ImpTex"
		EXTNAME			= "ImpTex"
		EXTDESCRIPTION	= "Importação de materiais."

		extdir = File.dirname(__FILE__).gsub(%r{//}) { "/" }
		extdir.force_encoding('UTF-8') if extdir.respond_to?(:force_encoding)
		EXTDIR = extdir

		loader = File.join( EXTDIR , EXTNAME , "main.rb" )

		EXTENSION				= SketchupExtension.new(EXTTITLE, loader)
		EXTENSION.creator		= "Flavio Tauchen"
		EXTENSION.description	= EXTDESCRIPTION
		EXTENSION.version		= EXTVERSION
		EXTENSION.copyright		= "Copyright 2010-#{Time.now.year} Tauchen Info"
		Sketchup.register_extension(EXTENSION, true)
	end
end
