from pathlib import Path
from html import escape
from PIL import Image as PILImage
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, Image, Preformatted, Flowable
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output' / 'pdf'
CAP = OUT / 'capturas'
PDF = OUT / 'HabitosApp_ACT02_Interfaces_y_componentes.pdf'
OUT.mkdir(parents=True, exist_ok=True)
pdfmetrics.registerFont(TTFont('Texto', r'C:\Windows\Fonts\arial.ttf'))
pdfmetrics.registerFont(TTFont('TextoNegrita', r'C:\Windows\Fonts\arialbd.ttf'))
pdfmetrics.registerFont(TTFont('Mono', r'C:\Windows\Fonts\consola.ttf'))
pdfmetrics.registerFontFamily('Texto', normal='Texto', bold='TextoNegrita', italic='Texto', boldItalic='TextoNegrita')
NEGRO = colors.black
BORDE = colors.HexColor('#d6d6d6')
CLARO = colors.HexColor('#f4f4f4')
ANCHO = A4[0] - 90
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='TituloApp', fontName='TextoNegrita', fontSize=28, leading=34, textColor=NEGRO, spaceAfter=8))
styles.add(ParagraphStyle(name='SeccionApp', fontName='TextoNegrita', fontSize=18, leading=23, textColor=NEGRO, spaceAfter=12))
styles.add(ParagraphStyle(name='SubApp', fontName='TextoNegrita', fontSize=11, leading=15, textColor=NEGRO, spaceBefore=12, spaceAfter=6))
styles.add(ParagraphStyle(name='CuerpoApp', fontName='Texto', fontSize=10, leading=14, textColor=NEGRO, spaceAfter=9))
styles.add(ParagraphStyle(name='PieApp', fontName='Texto', fontSize=8.2, leading=11, textColor=NEGRO, spaceAfter=6))
styles.add(ParagraphStyle(name='CodigoApp', fontName='Mono', fontSize=7.7, leading=9.4, textColor=NEGRO, spaceAfter=0))
story = []

def p(text, style='CuerpoApp'):
    return Paragraph(text, styles[style])

def titulo(text):
    story.append(p(text, 'SeccionApp'))

def par(text):
    story.append(p(text))

def codigo(text):
    panel = Table([[Preformatted(text.strip('\n'), styles['CodigoApp'])]], colWidths=[ANCHO])
    panel.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,-1),CLARO),('BOX',(0,0),(-1,-1),0.5,BORDE),
        ('LEFTPADDING',(0,0),(-1,-1),10),('RIGHTPADDING',(0,0),(-1,-1),10),
        ('TOPPADDING',(0,0),(-1,-1),9),('BOTTOMPADDING',(0,0),(-1,-1),9)]))
    story.append(panel)
    story.append(Spacer(1,8))

def tabla(rows, widths):
    datos = [[p(escape(str(c)), 'PieApp') for c in fila] for fila in rows]
    t=Table(datos,colWidths=widths,hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),CLARO),('GRID',(0,0),(-1,-1),0.5,BORDE),
        ('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),9),
        ('RIGHTPADDING',(0,0),(-1,-1),9),('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7)]))
    story.append(t)
    story.append(Spacer(1,10))

def foto(name, width=220, height=480):
    path=CAP/(name+'.png')
    with PILImage.open(path) as im:
        w,h=im.size
    scale=min(width/w,height/h)
    return Image(str(path),width=w*scale,height=h*scale)

def pantalla(title, intro, a, caption_a, b, caption_b, cierre):
    story.append(PageBreak())
    titulo(title)
    par(intro)
    images=Table([[foto(a), foto(b)], [p(caption_a,'PieApp'),p(caption_b,'PieApp')]], colWidths=[ANCHO/2,ANCHO/2])
    images.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP'),('ALIGN',(0,0),(-1,0),'CENTER'),
        ('TOPPADDING',(0,0),(-1,-1),5),('BOTTOMPADDING',(0,0),(-1,-1),8),
        ('LEFTPADDING',(0,0),(-1,-1),8),('RIGHTPADDING',(0,0),(-1,-1),8)]))
    story.append(images)
    story.append(Spacer(1,8))
    par(cierre)

titulo('ACT02. Interfaces y componentes')
par('Repositorio: <link href="https://github.com/paunadal14-web/HabitosAPP" color="#000000">github.com/paunadal14-web/HabitosAPP</link><br/>Usuario: pauchava.')
story.append(p('1. Organización y navegación','SubApp'))
tabla([
    ['Parte','Responsabilidad'],
    ['main.dart','Iniciar la aplicación, cargar los ajustes y configurar el tema.'],
    ['pantallas/','Mantener el estado y los controladores, navegar y llamar a los servicios.'],
    ['widgets/','Mostrar los datos recibidos y ejecutar las acciones mediante callbacks.'],
    ['modelos/','Representar usuarios, hábitos y estadísticas.'],
    ['servicios/','Acceder a SQLite y a las preferencias, y comprobar los permisos.'],
], [110,ANCHO-110])
story.append(p('Recorrido principal','SubApp'))
codigo('''Inicio de sesión -> Registro -> Mis hábitos
Inicio de sesión -> Mis hábitos -> Crear o editar hábito
Mis hábitos -> Estadísticas / Ajustes / Cerrar sesión
Mis hábitos -> Administración (solo administrador)
Administración -> Usuarios / Todos los hábitos / Estadísticas''')
par('La pantalla de edición sirve tanto para crear como para modificar. Al guardar, se vuelve a la lista y se recargan los datos. Cancelar vuelve sin guardar. El borrado se confirma con un AlertDialog antes de llamar al servicio.')
pantalla('2. Inicio de sesión y registro',
    'El acceso utiliza CampoTextoApp para usuario y contraseña, y BotonPrincipal para entrar. Crear cuenta abre el registro; desde este se puede volver al inicio de sesión.',
    '01_login','Inicio de sesión: la contraseña se escribe oculta.',
    '02_registro','Registro con datos de ejemplo. La fecha de creación se asigna al guardar.',
    'Se comprueba que los campos estén completos. El servicio verifica las credenciales y se muestra un mensaje si son incorrectas. La primera cuenta registrada es administradora; las siguientes reciben el rol de usuario.')
pantalla('3. Lista vacía y creación de un hábito',
    'Tras entrar, la lista muestra los hábitos de la cuenta. Cuando no hay ninguno, aparece un mensaje y el botón + permite crear el primero.',
    '03_lista_vacia','Mis hábitos antes de crear el primer registro.',
    '04_crear','Creación de Beber agua, con nombre vacío al abrir y azul como color inicial.',
    'El nombre se introduce con CampoTextoApp. Los colores se eligen mediante botones predefinidos. Guardar hábito ejecuta la acción de la pantalla, guarda en SQLite y vuelve a la lista.')
pantalla('4. Crear y marcar como completado',
    'El hábito recién creado aparece como pendiente. Su tarjeta comparte la misma estructura que las demás, pero recibe el nombre, el color y las acciones de ese registro.',
    '05_creado','Resultado de crear Beber agua: pendiente y progreso 0 de 5.',
    '06_completado','Al marcar la casilla: Completado hoy y progreso 1 de 5.',
    'La casilla ejecuta alCompletar con un booleano. La pantalla llama al servicio para guardar la fecha de hoy y actualizar la estadística. Volver a desmarcar retira esa fecha; marcar dos veces no duplica el día.')
pantalla('5. Edición y actualización de la lista',
    'Editar abre la misma pantalla de creación, con el nombre y el color actuales. En el ejemplo se cambia el nombre a Beber 2 litros de agua y el color a verde.',
    '07_editar','Formulario con el nuevo nombre y el color verde seleccionado.',
    '08_editado','La lista refleja los cambios y conserva el día completado.',
    'El callback alEditar está asociado al hábito de esa tarjeta. Guardar actualiza el registro existente, sin crear otro. Cancelar cierra el formulario sin modificar el hábito.')
pantalla('6. Reutilización y estadísticas del usuario',
    'Se crea un segundo hábito, Leer 20 minutos. Las dos tarjetas utilizan TarjetaHabito y reciben datos distintos. Las estadísticas se agrupan bajo el nombre de cada hábito.',
    '09_dos_habitos','Dos instancias de TarjetaHabito: un hábito pendiente y otro completado.',
    '10_estadisticas','Cada hábito muestra dos instancias de DatoEstadistica.',
    'DatoEstadistica recibe una etiqueta, un valor y un icono. En esta pantalla sirve para la racha actual y para los días completados. La cuenta de usuario solo consulta sus propios hábitos y estadísticas.')
pantalla('7. Eliminación de un hábito',
    'Eliminar en la tarjeta de Beber 2 litros de agua abre la confirmación. El componente solo comunica la acción; la pantalla decide cuándo pedir confirmación y llamar al servicio.',
    '11_confirmacion','AlertDialog antes de borrar el hábito y su estadística.',
    '12_eliminado','Después de confirmar, se conserva Leer 20 minutos.',
    'Cancelar en el diálogo conserva el registro. Borrar confirma la operación, elimina el hábito y su estadística, y recarga la lista. Cada tarjeta llama al callback del hábito correspondiente.')
pantalla('8. Administración y acceso a todos los hábitos',
    'Solo la cuenta administradora dispone del acceso a Administración. Esta pantalla reúne la gestión de usuarios, hábitos y estadísticas.',
    '14_admin','Pantalla de administración con los tres accesos de gestión.',
    '17_habitos_admin','Todos los hábitos identifica a su propietario: pauchava o Luis.',
    'Mis hábitos muestra los registros personales, también para un administrador. Desde Administración se accede al conjunto de cuentas. El servicio comprueba el rol y la propiedad en las operaciones; ocultar el botón no es la única comprobación.')
pantalla('9. Gestión de usuarios',
    'El administrador puede consultar usuarios, crear cuentas, editar sus datos y roles y eliminarlas. Se reutilizan CampoTextoApp y BotonPrincipal en el formulario de gestión.',
    '15_usuarios','Consulta de las cuentas de ejemplo y de sus roles.',
    '16_usuario_form','Formulario para crear una cuenta desde administración.',
    'Al editar se cargan los datos existentes y una contraseña nueva es opcional. Debe quedar al menos un administrador. El borrado de una cuenta pide confirmación y elimina también sus hábitos y estadísticas.')
pantalla('10. Gestión de estadísticas',
    'La vista de administración permite consultar las estadísticas de cualquier hábito y abrir su edición. Los datos visuales mantienen DatoEstadistica en las dos vistas.',
    '18_estadisticas_admin','Estadísticas con acciones de edición y borrado.',
    '19_estadistica_form','Formulario de una estadística, con hábito, racha y total.',
    'El administrador puede crear una estadística cuando un hábito no la tiene, editarla o borrarla. La racha no puede superar el total. Al marcar un día o cambiar las fechas del hábito, los valores vuelven a calcularse con su historial.')
pantalla('11. Ajustes y organización de archivos',
    'Los ajustes conservan el tema, el tamaño de letra, el objetivo diario y el filtro de hábitos completados. La organización de lib separa cada pantalla y cada componente en su archivo.',
    '13_ajustes','Ajustes de la cuenta, con el mismo campo y botón principal.',
    '20_carpetas','Captura del árbol real de carpetas y archivos del proyecto.',
    'Las pantallas crean sus TextEditingController y los liberan en dispose. Los cuatro componentes obligatorios heredan de StatelessWidget. Los widgets no consultan SQLite ni SharedPreferences.')

componentes = [
 ('12. CampoTextoApp','campo_texto_app.dart',
  '<b>Parámetros:</b> etiqueta muestra el nombre del campo; controller lo crea la pantalla. ocultar vale false por defecto y se activa para contraseñas. tipoTeclado, maxLineas, pista y ayuda adaptan el campo. validador revisa el valor, alEnviar recibe el texto al confirmar y habilitado impide editar mientras se guarda.',
  """CampoTextoApp(
  etiqueta: 'Usuario',
  controller: usuarioController,
  validador: obligatorio,
  habilitado: !entrando,
)"""),
 ('13. BotonPrincipal','boton_principal.dart',
  '<b>Parámetros:</b> texto indica la acción; alPulsar es un VoidCallback, una función sin argumentos. habilitado vale true por defecto. Cada pantalla le pasa su propia acción: entrar, registrar o guardar. El tamaño de texto, el espaciado, el color y el borde se definen una sola vez.',
  """BotonPrincipal(
  texto: entrando ? 'Entrando...' : 'Entrar',
  alPulsar: entrar,
  habilitado: !entrando,
)"""),
]
for title, archivo, descripcion, ejemplo in componentes:
    story.append(PageBreak());titulo(title);par(descripcion)
    texto=(ROOT/'lib'/'widgets'/archivo).read_text(encoding='utf-8-sig')
    codigo('\n'.join(line for line in texto.splitlines() if line.strip()))
    story.append(p('Ejemplo de uso en login_page.dart','SubApp'));codigo(ejemplo)
    story.append(p('Código completo del archivo del proyecto. Se han omitido las líneas en blanco.', 'PieApp'))

texto=(ROOT/'lib/widgets/tarjeta_habito.dart').read_text(encoding='utf-8-sig')
lineas=[line for line in texto.splitlines() if line.strip()]
story.append(PageBreak());titulo('14. TarjetaHabito (1 de 2)')
par('<b>Parámetros:</b> nombre, color y completadoHoy describen el hábito. icono tiene un valor por defecto. detalle añade información de la pantalla y habilitado controla las acciones. alCompletar recibe un bool; alEditar y alEliminar son VoidCallback.')
codigo('\n'.join(lineas[:45]))
story.append(p('El código continúa en la página siguiente.', 'PieApp'))
story.append(PageBreak());titulo('14. TarjetaHabito (2 de 2)')
codigo('\n'.join(lineas[45:]))
story.append(p('Ejemplo de uso en habitos_page.dart','SubApp'))
codigo("""TarjetaHabito(
  nombre: habito.nombre,
  color: colorDelHabito(habito.color),
  completadoHoy: habito.completadoHoy,
  habilitado: !ocupado,
  alCompletar: (valor) => marcar(habito, valor),
  alEditar: () => editarHabito(habito),
  alEliminar: () => borrar(habito),
)""")
par('Las funciones conservan la referencia a habito en cada vuelta de la lista. Por eso editar o eliminar actúa sobre esa tarjeta. La confirmación del borrado, la llamada al servicio y setState permanecen en la pantalla.')

story.append(PageBreak());titulo('15. DatoEstadistica')
par('<b>Parámetros:</b> etiqueta indica qué dato se muestra; valor es un String; icono identifica el dato. color es opcional y utiliza índigo por defecto. El componente no calcula estadísticas: muestra los valores recibidos de la pantalla.')
texto=(ROOT/'lib/widgets/dato_estadistica.dart').read_text(encoding='utf-8-sig')
codigo('\n'.join(line for line in texto.splitlines() if line.strip()))
story.append(p('Ejemplos de uso en estadisticas_page.dart','SubApp'))
codigo("""DatoEstadistica(
  etiqueta: 'Racha actual',
  valor: '${estadistica.rachaActual}',
  icono: Icons.local_fire_department_outlined,
)
DatoEstadistica(
  etiqueta: 'Días completados',
  valor: '${estadistica.totalDias}',
  icono: Icons.event_available,
  color: Colors.green,
)""")

class DetalleBoton(Flowable):
    def __init__(self, path, color):
        Flowable.__init__(self)
        self.path=str(path);self.width=ANCHO/2-18
        with PILImage.open(path).convert('RGB') as im:
            w,h=im.size
            pix=im.load()
            filas=[]
            for y in range(h):
                cuenta=sum(1 for x in range(w) if all(abs(pix[x,y][k]-color[k])<8 for k in range(3)))
                if cuenta>w*0.55:filas.append(y)
            if not filas:raise ValueError(f'No se localiza el botón en {path}')
            self.box=(20,max(0,min(filas)-26),w-20,min(h,max(filas)+27))
            self.iw=w;self.ih=h
        self.height=(self.box[3]-self.box[1])*self.width/(self.box[2]-self.box[0])
    def draw(self):
        c=self.canv;c.saveState()
        clip=c.beginPath();clip.rect(0,0,self.width,self.height);c.clipPath(clip,stroke=0)
        scale=self.width/(self.box[2]-self.box[0])
        c.drawImage(self.path,-self.box[0]*scale,-(self.ih-self.box[3])*scale,
            width=self.iw*scale,height=self.ih*scale)
        c.restoreState()

story.append(PageBreak());titulo('16. Un cambio visual en un solo componente')
par('Primero se capturó BotonPrincipal con fondo azul y radio 4. Después se modificaron dos valores del mismo archivo: fondo índigo y radio 12. Las pantallas conservaron sus usos y sus callbacks.')
tabla([['Antes','Después'],['backgroundColor: Colors.blue','backgroundColor: Colors.indigo'],
    ['BorderRadius.circular(4)','BorderRadius.circular(12)']], [ANCHO/2,ANCHO/2])
story.append(p('Inicio de sesión: Entrar','SubApp'))
for antes, despues, etiqueta in [('antes_login','01_login','LoginPage'),('antes_habito','04_crear','EditarHabitoPage')]:
    if etiqueta=='EditarHabitoPage':story.append(p('Crear hábito: Guardar hábito','SubApp'))
    t=Table([[p('Antes','PieApp'),p('Después','PieApp')],
      [DetalleBoton(CAP/(antes+'.png'),(33,150,243)),DetalleBoton(CAP/(despues+'.png'),(63,81,181))]],
      colWidths=[ANCHO/2,ANCHO/2])
    t.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP'),('TOPPADDING',(0,0),(-1,-1),6),
        ('BOTTOMPADDING',(0,0),(-1,-1),12)]));story.append(t)
story.append(p('Los detalles anteriores son zonas de las capturas completas de las dos pantallas. Las capturas iniciales y el código anterior se conservan junto a esta memoria.', 'PieApp'))
story.append(p('Callbacks y comprobación de la reutilización','SubApp'))
par('Un callback es una función que se pasa por constructor. En el botón, alPulsar ejecuta la acción de esa pantalla. En la tarjeta, alCompletar comunica el nuevo valor de la casilla y alEliminar avisa a la pantalla para que pida confirmación. Los componentes no necesitan conocer la base de datos.')
par('Las pruebas comprueban que CampoTextoApp oculta la contraseña, que BotonPrincipal respeta habilitado, que dos tarjetas ejecutan acciones distintas y que DatoEstadistica muestra etiquetas y valores diferentes. También se han comprobado las consultas, los permisos y el guardado de SQLite.')
par('<b>Resultado:</b> 15 pruebas automáticas correctas y un recorrido adicional correcto de navegación y capturas. El análisis del código no detecta incidencias. La captura documental se ejecuta de forma explícita y se omite en una ejecución normal de las pruebas.')

class Paginas(canvas.Canvas):
    def __init__(self,*args,**kwargs):
        canvas.Canvas.__init__(self,*args,**kwargs);self.estados=[]
    def showPage(self):
        self.estados.append(dict(self.__dict__));self._startPage()
    def save(self):
        for estado in self.estados:
            self.__dict__.update(estado)
            self.setFont('Texto',8);self.setFillColor(NEGRO)
            self.drawCentredString(A4[0]/2,25,str(self._pageNumber))
            canvas.Canvas.showPage(self)
        canvas.Canvas.save(self)

doc=SimpleDocTemplate(str(PDF),pagesize=A4,leftMargin=45,rightMargin=45,topMargin=50,bottomMargin=44,
    title='HabitosApp - ACT02 Interfaces y componentes',author='HabitosApp')
doc.build(story,canvasmaker=Paginas)
print(PDF)
