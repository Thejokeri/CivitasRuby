# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

require_relative 'diario'
require_relative 'titulo_propiedad'


module Civitas
  class Jugador
    attr_reader :num_casilla_actual, :puede_comprar, :encarcelado, :nombre, 
                :propiedades, :saldo, :casas_max, :hoteles_max, :casas_por_hotel,
                :precio_libertad, :paso_por_salida
    
    @@casas_max = 4
    @@casas_por_hotel = 4
    @@hoteles_max = 4
    @@paso_por_salida = 1000
    @@precio_libertad = 200
    @@saldo_inicial = 7500
    
    def initialize (nombre = nil, otro = nil)
      @nombre = nombre
      @num_casilla_actual = 0
      @saldo = @@saldo_inicial
      @propiedades = []
      
      unless otro.nil?
        @encarcelado = otro.encarcelado
        @nombre = otro.nombre
        @num_casilla_actual = otro.num_casilla_actual
        @puede_comprar = otro.puede_comprar
        @saldo = otro.saldo
        @propiedades = otro.propiedades
      end
    end
   
    def self.casas_max
      @@casas_max
    end
    
    def self.hoteles_max
      @@hoteles_max
    end
    
    def cancelar_hipoteca(ip) 
      result = false
      
      if @encarcelado
        return result
      end
      
      if existe_la_propiedad(ip)
        propiedad = @propiedades[ip]
        cantidad = propiedad.importe_cancelar_hipoteca
        puedo_gastar = self.puedo_gastar(cantidad)
        
        if puedo_gastar
          result = propiedad.cancelar_hipoteca(self)
          
          if result
            Diario.instance.ocurre_evento("El jugador #{@nombre} cancela la hipoteca de la propiedad #{@ip}")
          end
        end
      end
      
      return result
    end
    
    def cantidad_casas_hoteles
      cantidad = 0
      
      @propiedades.each do |propiedad|
        cantidad += propiedad.cantidad_casas_hoteles
      end
      
      return cantidad
    end
    
    def <=>(otro) 
      return @saldo <=> otro.saldo
    end
    
    def comprar(titulo) 
      result = false
      
      if @encarcelado
        return result
      end
      
      if @puede_comprar
        precio = titulo.precio_compra
        
        if self.puedo_gastar(precio)
          result = titulo.comprar(self)
          
          if result
            @propiedades << titulo
            Diario.instance.ocurre_evento("El jugador #{@nombre} compra la propiedad #{titulo.nombre}")
          end
          
          @puede_comprar = false
        end
      end
      
      return result
    end
    
    def construir_casa(ip) 
      result = false
      
      if @encarcelado
        return result
      end
      
      if existe_la_propiedad(ip)
        propiedad = @propiedades[ip]
        puedo_edificar_casa = puedo_edificar_casa(propiedad)
        
        if puedo_edificar_casa
          result = propiedad.construir_casa(self)
          
          if result
            Diario.instance.ocurre_evento("El jugador #{@nombre} construye casa en la propiedad #{ip}")
          end
        end
      end
    end
    
    def construir_hotel(ip) 
      result = false
      
      if @encarcelado
        return result
      end
      
      if existe_la_propiedad(ip) 
        propiedad = @propiedades[ip]
        puedo_edificar_hotel = puedo_edificar_hotel(propiedad)
        
        if puedo_edificar_hotel
          result = propiedad.construir_hotel(self)
          
          casas_por_hotel = @@casas_por_hotel
          propiedad.derruir_casas(casas_por_hotel, self)
          Diario.instance.ocurre_evento("El jugador #{@nombre} construye hotel en la propiedad #{ip}")
        end
      end
      
      return result
    end
    
    def en_bancarrota
      return @saldo <= 0
    end
    
    def encarcelar(num_casilla_carcel) 
      if self.debe_ser_encarcelado
        self.mover_casilla(num_casilla_carcel)
        @encarcelado = true
        Diario.instance.ocurre_evento("El jugador ha sido encarcelado")
      end
      
      return @encarcelado
    end
    
    def hipotecar(ip) 
      result = false
      
      if @encarcelado
        return result
      end
      
      if existe_la_propiedad(ip)
        propiedad = @propiedades[ip]
        result = propiedad.hipotecar(self)
      end
      
      if result
        Diario.instance.ocurre_evento("El jugador #{@nombre} hipoteca la propiedad #{ip}")
      end
      
      return result
    end
    
    def modificar_saldo(cantidad) 
      @saldo += cantidad
      Diario.instance.ocurre_evento("Se ha modificado el saldo")
      
      return true
    end
    
    def mover_casilla(num_casilla) 
      salida = false
      
      if !@encarcelado
        @num_casilla_actual = num_casilla
        @puedo_comprar = false
        Diario.instance.ocurre_evento("Se ha movido el jugador #{num_casilla} casillas")
        salida = true
      end
      
      return salida
    end
    
    def obtener_salvoconducto(sorpresa) 
        salida = false
        
      if !@encarcelado
        salida = true
        @salvoconducto = sorpresa
      end
      
      return salida
    end
    
    def paga(cantidad) 
      return self.modificar_saldo(-1*cantidad)
    end
    
    def paga_alquiler(cantidad) 
      salida = false
      
      if !@encarcelado
        salida = self.paga(cantidad)
        Diario.instance.ocurre_evento("El jugador paga el alquiler")
      end
      
      return salida
    end
    
    def paga_impuesto(cantidad) 
      salida = false
      
      if !@encarcelado
        salida = self.paga(cantidad)
        Diario.instance.ocurre_evento("El jugador paga el impuesto")
      end
      
      return salida
    end
    
    def pasa_por_salida
      modificar_saldo(1000)
      Diario.instance.ocurre_evento("El jugador ha pasado por la salida")
      
      return true
    end
    
    def puede_comprar_casilla 
      @puede_comprar = !@encarcelado
      
      return @puede_comprar
    end
    
    def recibe(cantidad) 
      salida = false
      
      if !@encarcelado
        salida = modificar_saldo(cantidad)
        Diario.instance.ocurre_evento("El jugador recibe el pago")
      end
      
      return salida
    end
    
    def salir_carcel_pagando
      salida = false
      
      if @encarcelado && puede_salir_carcel_pagando
        salida = true
        self.paga(200)
        @encarcelado = false
        Diario.instance.ocurre_evento("El jugador ha salido de la carcel pagando")
      end
      
      return salida
    end
    
    def salir_carcel_tirando 
      salida = Dado.instance.salgo_de_la_carcel
      
      if salida
        @encarcelado = false
        Diario.instance.ocurre_evento("El jugador ha salido de la carcel tirando")
      end
      
      return salida
    end
    
    def tiene_algo_que_gestionar
      return !@propiedades.empty?
    end
    
    def tiene_salvoconducto
      return !@salvoconducto.nil?
    end
    
    def vender(ip) 
      salida = false
      
      if !@encarcelado
        if existe_la_propiedad(ip) && @propiedades[ip].vender(self)
          Diario.instance.ocurre_evento("Se ha venido la propiedad #{@propiedades[ip].nombre}")
          @propiedades.delete_at(ip)
          salida = true
        end
        
        return salida
      end
      
      return salida
    end
    
    def to_s() 
      s = "\nNombre: #{@nombre} \nSaldo: #{@saldo} \n*---* Propiedades *---*\n" 
      
      #if !@propiedades.empty?
      #  @propiedades.each { |n|
      #    s = s + n.to_s + "\n"
      #  }
      #else
      #  s += "No tiene propiedades\n"
      #end
      
      return s
    end
    
    protected
    
    def debe_ser_encarcelado 
      salida = true
      
      unless @encarcelado 
        if self.tiene_salvoconducto
          salida = false
          perder_salvoconducto
          Diario.instance.ocurre_evento("El jugador se ha librado de la carcel")
        end
      end
      
      return salida
    end
    
    def puedo_gastar(precio) 
      salida = false
      
      if !@encarcelado
        salida = (@saldo >= precio)
      end
      
      return salida
    end
    
    private
    
    def existe_la_propiedad(ip) 
      return !@propiedades[ip].nil?
    end
    
    def perder_salvoconducto 
      @salvoconducto.usada
      @salvoconducto = nil
    end
    
    def puede_salir_carcel_pagando 
      return @saldo >= 200
    end
    
    def puedo_edificar_casa(propiedad) 
      puedo_edificar_casa = false
      
      precio = propiedad.precio_edificar
      
      if self.puedo_gastar(precio)
        if propiedad.num_casas < @@casas_max
          puedo_edificar_casa = true
        end
      end
      
      return puedo_edificar_casa
    end
    
    def puedo_edificar_hotel(propiedad)
      puedo_edificar_hotel = false
      
      precio = propiedad.precio_edificar
      
      if self.puedo_gastar(precio)
        if propiedad.num_hoteles < @@hoteles_max
          if propiedad.num_casas >= @@casas_por_hotel
            puedo_edificar_hotel = true
          end
        end
      end
      
      return puedo_edificar_hotel
    end
  end
end
