FLTK_WRAP_UI(ShapeWorksShop CorrespondenceGUI.fl)

ADD_EXECUTABLE(ShapeWorksShop ShapeWorksShop.cxx ShapeWorksShopApp.cxx ${ShapeWorksShop_FLTK_UI_SRCS})
TARGET_LINK_LIBRARIES(ShapeWorksShop VtkUtilities Utilities ITKParticleSystem ITKIO ITKNumerics ITKBasicFilters ITKCommon params ITKVtkFltk vtkIO vtkWidgets vtkRendering vtkImaging vtkFiltering vtkHybrid vtkGraphics vtkCommon ${FLTK_LIBRARIES})
INSTALL(TARGETS ShapeWorksShop   RUNTIME DESTINATION .)
