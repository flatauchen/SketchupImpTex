=begin
#===================================================================#
#	Plugin para importação de materiais com a possibilidade de		#
#	importar todas as imagens de uma pasta ou selecionar apenas		#
#	um arquivo de imagem com suporte para arquivos JPG e PNG.		#
#	Desenvolvido por: Flavio Tauchen								#
#===================================================================#
=end
# main.rb
require 'sketchup.rb'

# Cria a toolbar
unless file_loaded?(__FILE__)

	# Verifica Idioma
	if Sketchup.get_locale.downcase == "pt-br"
		toolnomepasta		= "Importar Pasta"
		tooltippasta		= "Importar Pasta de Texturas jpg e png.\nArquivos nomeados com as medidas\nex: 'Descrição Largura x Altura .jpg\/png' poderão ser importados automáticamente."
		toolnomeimagem		= "Importar Imagem"
		tooltipimagem		= "Importar Imagem de Textura jpg e png.\nArquivos nomeados com as medidas\nex: 'Descrição Largura x Altura .jpg\/png' poderão ser importados automáticamente."
	else
		toolnomepasta		= "Folder import"
		tooltippasta		= "Import Texture Folder jpg and png.\nFiles named with measurements\neg: 'Description Width x Height .jpg\/png' can be imported automatically."
		toolnomeimagem		= "File import"
		tooltipimagem		= "Import Texture Image jpg and png.\nFiles named with measurements\neg: 'Description Width x Height .jpg\/png' can be imported automatically."
	end

	# Define a toolbar
	barimp = UI::Toolbar.new("ImpTex")

	# Executa o módulo do botão Importar Pasta
	imppas = UI::Command.new(toolnomepasta) do
		Sketchup.active_model.select_tool FlaTauchen::TiImpTex::ImpPas.new
	end

	# Define Características do botão Importar Pasta
	imppas.small_icon = imppas.large_icon = File.join(File.dirname(__FILE__).gsub('\\', '/'), "img/imppas.png")
	imppas.tooltip = toolnomepasta
	imppas.status_bar_text = tooltippasta
	barimp.add_item imppas

	# Executa o módulo do botão Importar Imagem
	impimg = UI::Command.new(toolnomeimagem) do
		Sketchup.active_model.select_tool FlaTauchen::TiImpTex::ImpImg.new
	end

	# Define Características do botão Importar Imagem
	impimg.small_icon = impimg.large_icon = File.join(File.dirname(__FILE__).gsub('\\', '/'), "img/impimg.png")
	impimg.tooltip = toolnomeimagem
	impimg.status_bar_text = tooltipimagem
	barimp.add_item impimg

	# Mostra a toolbar e define a posição
	barimp.show unless barimp.get_last_state == 0
	file_loaded(__FILE__)
end

# Módulo do desenvolvedor
module FlaTauchen

	module TiImpTex # Módulo de Importação

		class DialogoDimensoes # Classe Diálogo
			def initialize
				@img_larg = "0"
				@img_alt = "0"
				criar_dialogo
			end

			def criar_dialogo

				# Verifica Idioma
				if Sketchup.get_locale.downcase == "pt-br"
					lang_largura	= "Largura:"
					lang_altura		= "Altura:"
					lang_dimencent	= "Dimensões em Centímetros"
					lang_dimeinv	= "As dimensões não são válidas!"
				else
					lang_largura	= "Width:"
					lang_altura		= "Height:"
					lang_dimencent	= "Dimensions in Centimeters"
					lang_dimeinv	= "The dimensions are not valid!"
				end # fim do if

				loop do
					prompts = [lang_largura, lang_altura]
					defaults = ["0","0"]
					input = UI.inputbox(prompts, defaults, lang_dimencent)

					if input[0].to_f.zero? && input[1].to_f.zero?
						@img_larg = input[0].gsub(',', '.').to_f
						@img_alt = input[1].gsub(',', '.').to_f
						break
					elsif input[0].to_f.zero? || input[1].to_f.zero?
						UI.messagebox(lang_dimeinv, MB_OK)
					else
						@img_larg = input[0].gsub(',', '.').to_f
						@img_alt = input[1].gsub(',', '.').to_f
						break
					end # fim do if
				end # fim do loop
			end # fim do método criar_dialogo

			def obter_dimensoes
				[@img_larg, @img_alt]
			end # fim do método obter_dimensoes
		end

		class ImpPas # Classe Pasta

			def initialize
				@texturas_pasta = escolher_pasta
				if @texturas_pasta
					@img_larg, @img_alt = obter_dimensoes_usuario
					importar_pasta(@img_larg, @img_alt)
				end
			end # fim do método initialize

			def importar_pasta(largura_padrao, altura_padrao)

				# Verifica Idioma
				if Sketchup.get_locale.downcase == "pt-br"
					lang_dimeinv	= "As dimensões não são válidas!"
					lang_semdim12	= "O arquivo \""
					lang_semdim22	= "\" não possui as dimensões, insira por favor!"
					lang_aplictd	= "Aplicar isso a todos?"
					lang_formato	= "Arquivos nomeados com as medidas\nex: 'Descrição Largura x Altura .jpg\/png' poderão ser importados automáticamente."
				else
					lang_dimeinv	= "The dimensions are not valid!"
					lang_semdim12	= "The file \""
					lang_semdim22	= "\" does not have the dimensions, please insert them!"
					lang_aplictd	= "Apply this to everyone?"
					lang_formato	= "Files named with measurements\neg: 'Description Width x Height .jpg\/png' can be imported automatically."
				end

				model = Sketchup.active_model
				operation = model.start_operation('Importar Texturas', true) # Inicia a operação
				texturas_para_importar = []

				@texturas_pasta.each do |textura|
					# Obtém o nome do material a partir do nome do arquivo
					nome_material = File.basename(textura, File.extname(textura))

					# Extrai as dimensões da imagem a partir do nome do material
					nome_tamanho = nome_material.gsub(',', '.')
					tamanho = nome_tamanho.downcase.scan(/(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)/).last

					if tamanho
					tamanho = tamanho.map(&:to_f)
							img_larg = tamanho.max
							img_alt = tamanho.min
					else
						if largura_padrao.to_f.zero? && altura_padrao.to_f.zero?
							UI.messagebox("#{lang_semdim12}#{nome_material}#{lang_semdim22}\n#{lang_formato}", MB_OK)
							loop do
								img_larg, img_alt = obter_dimensoes_usuario
								para_todos = UI.messagebox(lang_aplictd, MB_YESNO)

								if para_todos == IDNO
									break if validar_dimensoes(img_larg, img_alt)
									UI.messagebox(lang_dimeinv, MB_OK)
								else
									if validar_dimensoes(img_larg, img_alt)
										largura_padrao, altura_padrao = img_larg, img_alt
										break
									else
										UI.messagebox(lang_dimeinv, MB_OK)
									end
								end

							end
						else
							img_larg = largura_padrao
							img_alt = altura_padrao
						end
					end

					texturas_para_importar << {
						nome_material: nome_material,
						textura: textura,
						img_larg: img_larg,
						img_alt: img_alt
					}
				end

				# Executa todas as operações fora do loop
				texturas_para_importar.each do |textura_info|
					material = model.materials.add(textura_info[:nome_material])
					material.texture = textura_info[:textura]
					material.texture.size = (textura_info[:img_larg] > textura_info[:img_alt]) ? [textura_info[:img_larg].cm, textura_info[:img_alt].cm] : [textura_info[:img_alt].cm, textura_info[:img_larg].cm]
					largura = textura_info[:img_larg]
					altura = textura_info[:img_alt]
					puts "Material: " + textura_info[:nome_material]
					puts "Dimensões: Largura #{largura} x Altura #{altura}"
					puts "Imagem: " + textura_info[:textura]
					puts ""
				end # fim do loop
				model.commit_operation # Finaliza a operação

			end # fim do método importar_pasta

			def escolher_pasta

				# Verifica Idioma
				if Sketchup.get_locale.downcase == "pt-br"
					lang_selpst		= "Selecione a pasta com as imagens"
				else
					lang_selpst		= "Select the folder with the images"
				end

				pasta = UI.select_directory(title: lang_selpst)
				if pasta
					arq_img = Dir.entries(pasta).select do |arquivo|
						arquivo.end_with?('.jpg', '.png')
					end.map do |arquivo|
						caminho = File.join(pasta, arquivo).gsub('\\', '/')
						caminho.encode('UTF-8')
					end
					if !arq_img.empty?
						return arq_img
					end
				end
			end # fim do método escolher_pasta

			def obter_dimensoes_usuario
				dialogo = TiImpTex::DialogoDimensoes.new
				dialogo.obter_dimensoes
			end # fim do método obter_dimensoes_usuario

			def validar_dimensoes(largura, altura)
				return false if largura.to_f.zero? || altura.to_f.zero?
				true
			end # fim do método validar_dimensoes

		end # fim da classe ImpPas

		class ImpImg # Classe Imagem

			def initialize
				@textura_arquivo = escolher_arquivo
				if @textura_arquivo
					@img_larg, @img_alt = obter_dimensoes_usuario
					importar_arquivo(@img_larg, @img_alt)
				end
			end

			def importar_arquivo(largura_padrao, altura_padrao)

				# Verifica Idioma
				if Sketchup.get_locale.downcase == "pt-br"
					lang_dimeinv	= "As dimensões não são válidas!"
					lang_semdim12	= "O arquivo \""
					lang_semdim22	= "\" não possui as dimensões, insira por favor!"
					lang_formato	= "Arquivos nomeados com as medidas\nex: 'Descrição Largura x Altura .jpg\/png' poderão ser importados automáticamente."
				else
					lang_dimeinv	= "The dimensions are not valid!"
					lang_semdim12	= "The file \""
					lang_semdim22	= "\" does not have the dimensions, please insert them!"
					lang_formato	= "Files named with measurements\neg: 'Description Width x Height .jpg\/png' can be imported automatically."
				end

				model = Sketchup.active_model
				operation = model.start_operation('Importar Texturas', true) # Inicia a operação

				# Define nome do material e dimensões
				nome_material = File.basename(@textura_arquivo, File.extname(@textura_arquivo))
				nome_tamanho = nome_material.gsub(',', '.')
				tamanho = nome_tamanho.downcase.scan(/(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)/).last

				if largura_padrao.to_f.zero? && altura_padrao.to_f.zero?
					if tamanho
						tamanho = tamanho.map(&:to_f)
						img_larg = tamanho.max
						img_alt = tamanho.min
					else
						UI.messagebox("#{lang_semdim12}#{nome_material}#{lang_semdim22}\n#{lang_formato}", MB_OK)
						loop do
							img_larg, img_alt = obter_dimensoes_usuario
							break if validar_dimensoes(img_larg, img_alt)
							UI.messagebox(lang_dimeinv, MB_OK)
						end # fim do loop
					end
				else
					img_larg = largura_padrao
					img_alt = altura_padrao
				end # fim do if

				material = Sketchup.active_model.materials.add(nome_material)
				material.texture = @textura_arquivo
				material.texture.size = (img_larg > img_alt) ? [img_larg.cm, img_alt.cm] : [img_alt.cm, img_larg.cm]
				puts "Material: " + nome_material
				puts "Dimensões: Largura " + img_larg.to_s + " x Altura " + img_alt.to_s
				puts "Imagem: " + @textura_arquivo
				puts ""
				model.commit_operation # Finaliza a operação
			end # fim do método importar_arquivo

			def escolher_arquivo

				# Verifica Idioma
				if Sketchup.get_locale.downcase == "pt-br"
					lang_selpst		= "Selecione um arquivo de imagem"
				else
					lang_selpst		= "Select an image file"
				end

				arquivo = UI.openpanel('Selecione o arquivo de imagem', '', 'Image Files|*.jpg;*.png;||')
				arquivo = arquivo.encode('UTF-8')
				if arquivo && (arquivo.end_with?('.jpg', '.png'))
					return arquivo.gsub('\\', '/')
				end
			end # fim do método escolher_arquivo

			def obter_dimensoes_usuario
				dialogo = TiImpTex::DialogoDimensoes.new
				dialogo.obter_dimensoes
			end # fim do método obter_dimensoes_usuario

			def validar_dimensoes(largura, altura)
				return false if largura.to_f.zero? || altura.to_f.zero?
				true
			end # fim do método validar_dimensoes

		end # fim da classe ImpImg
	end
end