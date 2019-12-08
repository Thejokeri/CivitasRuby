# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Civitas
  class SorpresaPagarCobrar < Sorpresa
    def initialize(valor, texto)
      super.init
      @valor = valor
      @texto = texto
    end
    
    def aplicarAJugador_pagarCobrar(actual, todos) 
      if (super.jugadorCorrecto(actual, todos))
        super.informe(actual,todos)
        jugador = todos[actual]
        jugador.modificarSaldo(@valor)
      end
    end
  end
end
