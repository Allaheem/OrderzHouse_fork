/**
 * Shared authorization for project-scoped resources (details, files, timeline).
 * Aligns with marketplace visibility in projectsFiltering buildStatusCondition.
 */

export const isProjectPubliclyListable = (p) => {
  if (!p || p.is_deleted) return false;
  const admin = p.admin_approval_status;
  const adminOk =
    admin === "none" ||
    admin === "approved" ||
    admin === null ||
    admin === undefined;
  if (!adminOk) return false;
  const pt = p.project_type;
  const st = p.status;
  if (pt === "fixed" || pt === "hourly") return st === "active";
  if (pt === "bidding") return st === "bidding";
  return false;
};

/**
 * @param projectRow — needs user_id, project_type, status, admin_approval_status, is_deleted
 */
export const userMayAccessProjectDetails = async (
  pool,
  projectRow,
  projectId,
  userId,
  roleId
) => {
  const isAdmin = Number(roleId) === 1;
  const isOwner =
    userId != null && Number(projectRow.user_id) === Number(userId);
  const isPublic = isProjectPubliclyListable(projectRow);
  if (isAdmin || isOwner || isPublic) return true;
  if (userId == null) return false;
  const { rows: ar } = await pool.query(
    `SELECT 1 FROM project_assignments
     WHERE project_id = $1 AND freelancer_id = $2
       AND status NOT IN ('rejected', 'not_chosen')`,
    [projectId, userId]
  );
  return ar.length > 0;
};
