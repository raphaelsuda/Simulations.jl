from abaqus import *
from abaqusConstants import *
session.Viewport(name='Viewport: 1', origin=(0.0, 0.0), width=268.952117919922,
height=154.15299987793)
session.viewports['Viewport: 1'].makeCurrent()
session.viewports['Viewport: 1'].maximize()
from caeModules import *
from driverUtils import executeOnCaeStartup
executeOnCaeStartup()
name='XXXX.odb'
o1 = session.openOdb(name)
session.viewports['Viewport: 1'].setValues(displayedObject=o1)
session.xyDataListFromField(odb=o1, outputPosition=NODAL, variable=(('RF', NODAL, ((COMPONENT, 'RF1'), (COMPONENT, 'RF3'))), ), nodeSets=('SEB', 'SET', 'NWB', 'NWT', ))
nodeSEB = session.odbs[name].rootAssembly.nodeSets["SEB"].nodes[0][0].label
nodeSET = session.odbs[name].rootAssembly.nodeSets["SET"].nodes[0][0].label
nodeNWB = session.odbs[name].rootAssembly.nodeSets["NWB"].nodes[0][0].label
nodeNWT = session.odbs[name].rootAssembly.nodeSets["NWT"].nodes[0][0].label
instanceSEB = session.odbs[name].rootAssembly.nodeSets["SEB"].instanceNames[0]
instanceSET = session.odbs[name].rootAssembly.nodeSets["SET"].instanceNames[0]
instanceNWB = session.odbs[name].rootAssembly.nodeSets["NWB"].instanceNames[0]
instanceNWT = session.odbs[name].rootAssembly.nodeSets["NWT"].instanceNames[0]
rf1_SEB = session.xyDataObjects['RF:RF1 PI: '+instanceSEB+' N: '+str(nodeSEB)]
rf1_SET = session.xyDataObjects['RF:RF1 PI: '+instanceSET+' N: '+str(nodeSET)]
rf1_NWB = session.xyDataObjects['RF:RF1 PI: '+instanceNWB+' N: '+str(nodeNWB)]
rf1_NWT = session.xyDataObjects['RF:RF1 PI: '+instanceNWT+' N: '+str(nodeNWT)]
rf3_SEB = session.xyDataObjects['RF:RF3 PI: '+instanceSEB+' N: '+str(nodeSEB)]
rf3_SET = session.xyDataObjects['RF:RF3 PI: '+instanceSET+' N: '+str(nodeSET)]
rf3_NWB = session.xyDataObjects['RF:RF3 PI: '+instanceNWB+' N: '+str(nodeNWB)]
rf3_NWT = session.xyDataObjects['RF:RF3 PI: '+instanceNWT+' N: '+str(nodeNWT)]
rf11 = sum((rf1_SEB, rf1_SET))
rf11.setValues(
    sourceDescription='sum ( ( "RF:RF1 PI: '+instanceSEB+' N: +str(nodeSEB)", "RF:RF1 PI: '+instanceSET+' N: +str(nodeSET)" ) )')
tmpName = rf11.name
session.xyDataObjects.changeKey(tmpName, 'RF11')
x0 = session.xyDataObjects['RF11']
session.writeXYReport(fileName='reaction_forces/RF11.rpt', appendMode=OFF, xyData=(x0, 
    ))
rf33 = sum((rf3_NWB, rf3_NWT))
rf33.setValues(
    sourceDescription='sum ( ( "RF:RF3 PI: '+instanceNWB+' N: +str(nodeNWB)", "RF:RF1 PI: '+instanceNWT+' N: +str(nodeNWT)" ) )')
tmpName = rf33.name
session.xyDataObjects.changeKey(tmpName, 'RF33')
x0 = session.xyDataObjects['RF33']
session.writeXYReport(fileName='reaction_forces/RF33.rpt', appendMode=OFF, xyData=(x0, 
    ))
rf13 = sum((rf3_SEB, rf3_SET))
rf13.setValues(
    sourceDescription='sum ( ( "RF:RF3 PI: '+instanceSEB+' N: +str(nodeSEB)", "RF:RF3 PI: '+instanceSET+' N: +str(nodeSET)" ) )')
tmpName = rf13.name
session.xyDataObjects.changeKey(tmpName, 'RF13')
x0 = session.xyDataObjects['RF13']
session.writeXYReport(fileName='reaction_forces/RF13.rpt', appendMode=OFF, xyData=(x0, 
    ))
rf31 = sum((rf1_NWB, rf1_NWT))
rf31.setValues(
    sourceDescription='sum ( ( "RF:RF1 PI: '+instanceNWB+' N: +str(nodeNWB)", "RF:RF1 PI: '+instanceNWT+' N: +str(nodeNWT)" ) )')
tmpName = rf31.name
session.xyDataObjects.changeKey(tmpName, 'RF31')
x0 = session.xyDataObjects['RF31']
session.writeXYReport(fileName='reaction_forces/RF31.rpt', appendMode=OFF, xyData=(x0, 
    ))
