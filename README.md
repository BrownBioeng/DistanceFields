# DistanceFields
Functions required to compute and use mesh distance fields. The distance field is consists of a grid of points distributed along a 3D bounding box containing the mesh. Each grid point is assigned a signed distance to the mesh surface, where positive values indicate the point is outside of the mesh, negative values indicate the point is inside of the mesh, and zero indicates the point is on the mesh surface. The signed distance of any point within the bounding box can be computed by interpolating between the grid points. 

These methods were first presented in:

Marai GE, Crisco JJ, Laidlaw DH. 2006 A kinematics-based method for generating cartilage maps and deformations in the multi-articulating wrist joint from CT images. Conf Proc IEEE Eng Med Biol Soc 1, 2079–2082. (doi:10.1109/IEMBS.2006.259742)

The distance field functions and dependent functions were developed by contributors at J.J. Crisco's lab at Brown University. Several functions were first written to contribute to the following publications: 

Crisco JJ, Coburn JC, Moore DC, Upal MA. 2005 Carpal bone size and scaling in men versus in women. J Hand Surg Am 30, 35–42. (doi:10.1016/j.jhsa.2004.08.012)

Crisco JJ, Upal MA, Moore DC. 2003 Advances in quantitative in vivo imaging. Current Opinion in Orthopaedics 14, 351–355.

Upal MA. 2003 A method for efficient examination of carpal bone kinematics from computed tomography data. PhD, Queen’s University. See https://library-archives.canada.ca/eng/services/services-libraries/theses/Pages/item.aspx?idNumber=52411112.

Functions built on previous publications cite these works in the annotated .m files. 
