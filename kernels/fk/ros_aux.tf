KPL/FK

Auxiliary frames by Bjoern Grieger

The frame ROS_AUX_NADIR is needed for ROVIS pointing computations.

   \begindata

      FRAME_ROS_AUX_NADIR          = -226910
      FRAME_-226910_NAME           = 'ROS_AUX_NADIR'
      FRAME_-226910_CLASS          =  5
      FRAME_-226910_CLASS_ID       =  -226910
      FRAME_-226910_CENTER         = 'ROSETTA'
      FRAME_-226910_RELATIVE       = 'J2000'
      FRAME_-226910_DEF_STYLE      = 'PARAMETERIZED'
      FRAME_-226910_FAMILY         = 'TWO-VECTOR'
      FRAME_-226910_ANGLE_SEP_TOL  = 0.000001
      FRAME_-226910_PRI_AXIS       = 'Z'
      FRAME_-226910_PRI_VECTOR_DEF = 'OBSERVER_TARGET_POSITION'
      FRAME_-226910_PRI_OBSERVER   = 'ROSETTA'
      FRAME_-226910_PRI_TARGET     = 'CHURYUMOV-GERASIMENKO'
      FRAME_-226910_PRI_ABCORR     = 'NONE'
      FRAME_-226910_SEC_AXIS       = 'X'
      FRAME_-226910_SEC_VECTOR_DEF = 'OBSERVER_TARGET_POSITION'
      FRAME_-226910_SEC_OBSERVER   = 'ROSETTA'
      FRAME_-226910_SEC_TARGET     = 'SUN'
      FRAME_-226910_SEC_ABCORR     = 'LT+S'

   \begintext

The frame 67P/C-G_ELLIPSOID is needed to use the ellipsoid shape model
with correct orientation relative to the polyhedron shape model.

   \begindata

      FRAME_67P/C-G_ELLIPSOID      =  -226913
      FRAME_-226913_NAME           = '67P/C-G_ELLIPSOID'
      FRAME_-226913_CLASS          =  4
      FRAME_-226913_CLASS_ID       =  -226913
      FRAME_-226913_CENTER         =  1000012
      TKFRAME_-226913_RELATIVE     = '67P/C-G_FIXED'
      TKFRAME_-226913_SPEC         = 'ANGLES'
      TKFRAME_-226913_UNITS        = 'DEGREES'
      TKFRAME_-226913_ANGLES       = (  0.00    0.00   22.39 )
      TKFRAME_-226913_AXES         = (  1       2       3    )

   \begintext
